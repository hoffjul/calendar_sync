require 'icalendar'

class SyncService
  def sync_all
    Synchronization.all.each do |sync|
      begin
        text = RestClient.get(sync.ics_url).body
        cal = Icalendar.parse(text).first
        cal.events.each do |event|
          cobot(sync).create_booking sync.subdomain, sync.resource_id, {
            from: event.start.utc.iso8601,
            to: event.end.utc.iso8601,
            title: event.summary
          }
        end
      rescue => e
        Raven.capture_exception(e)
      end
    end
  end

  private

  def cobot(synchronization)
    CobotClient.new(synchronization.access_token)
  end
end
