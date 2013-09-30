class Booking < ActiveRecord::Base
  scope :upcoming, ->() { where('"bookings"."from" > ?', Time.now) }
end
