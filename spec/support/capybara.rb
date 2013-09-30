require 'capybara/rspec'

Capybara.app = CobotIcalSync

RSpec.configure do |c|
  c.include Capybara::DSL
end
