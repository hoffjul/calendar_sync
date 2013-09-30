module SessionHelpers
  def log_in
    visit '/'
    click_link 'Log in'
  end
end

RSpec.configure do |c|
  c.include SessionHelpers
end
