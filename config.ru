ENV['RACK_ENV'] ||= ENV['RAILS_ENV']
require File.join(File.dirname(__FILE__), 'app.rb')

run CobotIcalSync.new
