class Synchronization < ActiveRecord::Base
  attr_accessor :resource_name

  validate :ics_url_is_not_from_cobot
  validate :ics_url_is_working

  has_many :bookings

  private

  def ics_url_is_not_from_cobot
    if ics_url? && ics_url.include?('cobot.me')
      errors.add :ics_url, 'cannot sync Cobot with itself'
    end
  end

  def ics_url_is_working
    if ics_url? && !valid_ics?(ics_url)
      errors.add :ics_url, 'is not a valid calendar file'
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
end
