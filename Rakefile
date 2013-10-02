require "sinatra/activerecord/rake"
require "./app"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  puts "Could not load RSpec."
end

task :sync_calendars do
  SyncService.new.sync_all
end
