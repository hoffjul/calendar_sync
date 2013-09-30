require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/activerecord'
require 'omniauth/strategies/cobot'

Dir['lib/*.rb'].each do |file|
  require_relative file
end

class CobotIcalSync < Sinatra::Base
  configure(:production) do
    set :cookie_secret, ENV['COOKIE_SECRET']
    use Raven::Rack
  end

  configure(:development) do
    set :cookie_secret, '1'
  end

  configure(:test) do
    set :cookie_secret, '1'
    OmniAuth.config.test_mode = true
  end

  use Rack::Session::Cookie, secret: CobotIcalSync.cookie_secret
  use Rack::MethodOverride

  use OmniAuth::Builder do
    provider :cobot, ENV['COBOT_CLIENT_ID'], ENV['COBOT_CLIENT_SECRET'],
      scope: "read write"
  end

  register Sinatra::ActiveRecordExtension

  get '/health' do
    status 200
  end

  get '/' do
    erb :home
  end

  get '/auth/:provider/callback' do
    session[:user] = auth_hash
    redirect '/spaces'
  end

  get '/spaces' do
    @spaces = current_user.admin_of
    erb :spaces
  end

  get '/spaces/:subdomain' do
    @space = current_user.space(params[:subdomain])
    @synchronizations = @space.synchronizations
    @resources = @space.resources
    erb :space
  end

  post '/spaces/:subdomain/synchronization' do
    space = current_user.space(params[:subdomain])
    Synchronization.create! ics_url: params[:ics_url], resource_id: params[:resource_id],
      subdomain: space.subdomain,
      access_token: space.access_token
    redirect "/spaces/#{params[:subdomain]}"
  end

  delete '/synchronizations/:id' do
    sync = Synchronization.find params[:id]
    sync.destroy if current_user.admin_of?(sync.subdomain)
    redirect "/spaces/#{sync.subdomain}"
  end

  helpers do
    def current_user
      User.new session[:user] if session[:user]
    end

    def auth_hash
      request.env['omniauth.auth']
    end
  end
end
