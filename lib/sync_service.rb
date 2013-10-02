require 'icalendar'
require 'rest_client'

class SyncService
  def sync_all
    Synchronization.all.each do |sync|
      begin
        text = RestClient.get(sync.ics_url).body
        cal = Icalendar.parse(text).first
        create_update_bookings sync, cal.events
        remove_deleted_bookings sync, cal.events
      rescue => e
        Raven.capture_exception(e)
      end
    end
  end

  def valid_ics?(url)
    begin
      Icalendar.parse RestClient.get(url).body
      true
    rescue
      false
    end
  end

  private

  def create_update_bookings(sync, events)
    events.each do |event|
      bookings = sync.bookings.where(uid: events.map(&:uid))
      if booking = bookings.find{|b| b.uid == event.uid}
        update_booking sync, event, booking
      else
        create_booking sync, event
      end
    end
  end

  def update_booking(sync, event, booking)
    if booking.event_changed?(event)
      cobot(sync).update_booking sync.subdomain, booking.cobot_id,
        booking_attributes(event)
      booking.update_attributes booking_attributes(event)
    end
  end

  def create_booking(sync, event)
    begin
      cobot_booking = cobot(sync).create_booking sync.subdomain, sync.resource_id,
        booking_attributes(event)
      sync.bookings.create!({cobot_id: cobot_booking[:id], uid: event.uid
        }.merge(booking_attributes(event)))
    rescue RestClient::UnprocessableEntity
      # ignore booking conflicts
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
        cobot(sync).delete_booking sync.subdomain, booking.cobot_id
      end
    end
  end

  def cobot(synchronization)
    CobotClient::ApiClient.new(synchronization.access_token)
  end
end
