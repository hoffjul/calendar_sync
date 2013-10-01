class Booking < ActiveRecord::Base
  scope :upcoming, ->() { where('"bookings"."from" > ?', Time.now) }

  def event_changed?(event)
    event.summary != title || event.start != from || event.end != to
  end
end
