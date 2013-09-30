require 'icalendar'

class SyncService
  def sync_all
    Synchronization.all.each do |sync|
      # begin
        text = RestClient.get(sync.ics_url).body
        cal = Icalendar.parse(text).first
        create_new_bookings sync, cal.events
        remove_deleted_bookings sync, cal.events
      # rescue => e
        # Raven.capture_exception(e)
      # end
    end
  end

  private

  def create_new_bookings(sync, events)
    events.each do |event|
      cobot_booking = cobot(sync).create_booking sync.subdomain, sync.resource_id, {
        from: event.start.utc.iso8601,
        to: event.end.utc.iso8601,
        title: event.summary
      }
      sync.bookings.create! cobot_id: cobot_booking[:id], uid: event.uid,
        from: event.start
    end
  end

  def remove_deleted_bookings(sync, events)
    sync.bookings.upcoming.each do |booking|
      unless events.map(&:uid).include?(booking.uid)
        cobot(sync).delete_booking sync.subdomain, booking.cobot_id
      end
    end
  end

  def cobot(synchronization)
    CobotClient.new(synchronization.access_token)
  end
end
