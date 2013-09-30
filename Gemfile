source 'https://rubygems.org'

ruby '2.0.0'

gem 'sinatra'
gem 'json'
gem 'rake'
gem 'activerecord'
gem 'pg'
gem 'rest-client'
gem 'sentry-raven'
gem 'sinatra-activerecord'
gem 'omniauth'
gem 'omniauth_cobot'
gem 'icalendar'
gem 'cobot_client', '~>0.5.0'

group :production do
  gem 'thin'
end

group :development do
  gem 'rspec'
  gem 'foreman'
end

group :test do
  gem 'rack-test'
  gem 'webmock'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'capybara'
  gem 'timecop'
end
