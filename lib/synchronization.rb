class Synchronization < ActiveRecord::Base
  attr_accessor :resource_name

  has_many :bookings
end
