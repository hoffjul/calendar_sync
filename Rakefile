require "sinatra/activerecord/rake"
require "./app"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
  puts "Could not load RSpec."
end

task :update_cache do
  Space.all.each(&:update_memberships_cache)
end
