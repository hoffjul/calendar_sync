require 'raven'

if ENV['RAVEN_DSN']
  Raven.configure do |config|
    config.dsn = ENV['RAVEN_DSN']
    config.excluded_exceptions << 'Sinatra::NotFound'
  end
end
