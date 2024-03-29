require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/activerecord'
require 'omniauth/strategies/cobot'
require 'cobot_client'

Dir['lib/*.rb'].each do |file|
  require_relative file
end

CobotClient::ApiClient.user_agent = 'Cobot iCal Sync'

class CobotIcalSync < Sinatra::Base
  layout 'layout'
  configure(:production) do
    set :cookie_secret, ENV['COOKIE_SECRET']
    use Raven::Rack
  end

  configure do
    ActiveRecord::Base.logger.level = Logger::WARN
  end

  configure(:development) do
    set :cookie_secret, '1'
    CobotClient::UrlHelper.site = ENV['COBOT_SITE']
    OmniAuth::Strategies::Cobot.option :client_options, site: ENV['COBOT_SITE'],
      token_url: '/oauth/access_token'
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

  before do
    if !current_user &&
      [%r{^/health$}, %r{^/help$}, %r{^/auth/*}, %r{^/$}].none?{|regex| request.path_info =~ regex}
      redirect '/'
    end
  end

  get '/health' do
    status 200
  end

  get '/' do
    erb :home
  end

  get '/log_out' do
    session.clear
    redirect '/'
  end

  get '/help' do
    erb :help
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
    @synchronization = Synchronization.new
    @resources = @space.resources
    erb :space
  end

  post '/spaces/:subdomain/synchronization' do
    @space = current_user.space(params[:subdomain])
    @synchronization = Synchronization.create ics_url: params[:ics_url],
      resource_id: params[:resource_id], subdomain: @space.subdomain,
      access_token: @space.access_token
    if @synchronization.save
      redirect "/spaces/#{params[:subdomain]}"
    else
      @synchronizations = @space.synchronizations
      @resources = @space.resources
      erb :space
    end
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
