ENV['RACK_ENV'] = 'test'
require File.dirname(__FILE__) + '/../app'
require 'rack/test'
require 'webmock/rspec'
Dir[File.dirname(__FILE__) + '/support/*.rb'].each {|f| require f }

RSpec.configure do |c|
  c.include Rack::Test::Methods

  def app
    CobotIcalSync.new
  end
end
