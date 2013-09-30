require 'icalendar'

class SyncService
  def sync_all
    Synchronization.all.each do |sync|
      # begin
        text = RestClient.get(sync.ics_url).body
        cal = Icalendar.parse(text).first
        create_update_bookings sync, cal.events
        remove_deleted_bookings sync, cal.events
      # rescue => e
        # Raven.capture_exception(e)
      # end
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
    cobot(sync).update_booking sync.subdomain, booking.cobot_id,
      booking_attributes(event)
  end

  def create_booking(sync, event)
    cobot_booking = cobot(sync).create_booking sync.subdomain, sync.resource_id,
      booking_attributes(event)
    sync.bookings.create! cobot_id: cobot_booking[:id], uid: event.uid,
      from: event.start
  end

  def booking_attributes(event)
    {
      from: event.start.utc.iso8601,
      to: event.end.utc.iso8601,
      title: event.summary
    }
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
