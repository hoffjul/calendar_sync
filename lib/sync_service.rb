require 'icalendar'
require 'rest_client'

class SyncService
  cattr_accessor :logger

  def sync_all
    Synchronization.all.each do |sync|
      debug "Syncing #{sync.ics_url} for #{sync.subdomain}"
      begin
        if text = load_ics(sync)
          cal = Icalendar::Parser.new(text, false).parse.first
          debug "Found #{cal.events.size} events."
          create_update_bookings sync, cal.events
          remove_deleted_bookings sync, cal.events
        end
      rescue => e
        debug "Error: #{e.message}"
        Raven.capture_exception(e)
      end
    end
  end

  private

  def load_ics(sync)
    begin
      RestClient.get(sync.ics_url).body
    rescue RestClient::ResourceNotFound
    end
  end

  def create_update_bookings(sync, events)
    bookings = sync.bookings.where(uid: events.map(&:uid))
    begin
      cobot_bookings = get_cobot_bookings(sync, events)
      events.each do |event|
        begin
          if booking = bookings.find{|b| b.uid == event.uid}
            update_booking sync, event, booking
          else
            create_booking sync, event, cobot_bookings
          end
        rescue RestClient::ResourceNotFound
          sync.destroy # resource was deleted on Cobot
        end
      end
    rescue RestClient::ResourceNotFound
      sync.destroy # space was deleted on cobot
    end
  end

  def update_booking(sync, event, booking)
    if booking.event_changed?(event)
      begin
        debug "updating booking #{booking.title} with #{booking_attributes(event).inspect}"
        cobot(sync).update_booking sync.subdomain, booking.cobot_id,
          booking_attributes(event)
        booking.update_attributes booking_attributes(event)
      rescue RestClient::UnprocessableEntity => e
        debug "error updating booking: #{e.message}"
        # ignore booking conflicts
      end
    else
      debug "not updating booking #{booking.title}"
    end
  end

  def create_booking(sync, event, cobot_bookings)
    begin
      debug "creating booking #{event.summary}"
      unless would_conflict?(event, cobot_bookings, sync.resource_id)
        cobot_booking = cobot(sync).create_booking sync.subdomain, sync.resource_id,
          booking_attributes(event)
        sync.bookings.create!({cobot_id: cobot_booking[:id], uid: event.uid
          }.merge(booking_attributes(event)))
      end
    rescue RestClient::UnprocessableEntity => e
      debug "error creating booking: #{e.message}"
      # ignore booking conflicts
    end
  end

  def would_conflict?(event, cobot_bookings, resource_id)
    from = booking_attributes(event)[:from]
    to = booking_attributes(event)[:to]
    cobot_bookings.select{|b| b[:resource][:id] == resource_id}.
      map{|b| Time.parse(b[:from])..Time.parse(b[:to])}.find do |range|
        from < range.first && to > range.end ||
        from < range.first && to > range.first ||
        from < range.end && to > range.end ||
        from > range.first && to < range.end
    end
  end

  def get_cobot_bookings(sync, events)
    if events.any?
      cobot(sync).get sync.subdomain, '/bookings',
        from: events.map{|e| format_time(e.start, :beginning)}.sort.first,
        to: events.map{|e| format_time(e.end, :end)}.sort.last
    else
      []
    end
  end

  def booking_attributes(event)
    {
      from: format_time(event.start, :beginning),
      to: format_time(event.end, :end),
      title: event.summary
    }
  end

  def format_time(date_or_time, beginning_or_end)
    if date_or_time.is_a?(DateTime)
      date_or_time
    else
      DateTime.parse("#{date_or_time.to_s} 00:00:00 +0000").utc.send("#{beginning_or_end}_of_day")
    end.utc.iso8601
  end

  def remove_deleted_bookings(sync, events)
    sync.bookings.upcoming.each do |booking|
      unless events.map(&:uid).include?(booking.uid)
        begin
          debug "deleting booking #{booking.title}"
          cobot(sync).delete_booking sync.subdomain, booking.cobot_id
        rescue RestClient::ResourceNotFound
          debug "booking already deleted"
        end
      end
    end
  end

  def cobot(synchronization)
    CobotClient::ApiClient.new(synchronization.access_token)
  end

  def debug(message)
    logger.debug message if logger
  end
end
