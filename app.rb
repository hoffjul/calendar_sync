require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/activerecord'
require 'omniauth/strategies/cobot'

require_relative 'lib/configure_raven'
require_relative 'lib/user'
require_relative 'lib/space'
require_relative 'lib/resource'
require_relative 'lib/synchronization'
require_relative 'lib/cobot_client'
require_relative 'lib/sync_service'

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

  # before('/spaces/:subdomain/*') do
  #   @space = Space.where(subdomain: params[:subdomain]).first!
  #   token = env['HTTP_X_COBOT_ACCESS_TOKEN']
  #   if token.blank?
  #     halt 401, {error: 'X-Cobot-Access-Token header missing.'}.to_json
  #   elsif @space.access_token != token
  #     halt 401, {error: 'Invalid access token.'}.to_json
  #   end
  # end

  # before do
  #   body = request.body.read
  #   request.body.rewind
  #   params.merge! Hash[::URI.decode_www_form(body)]
  # end

  # post "/spaces/:subdomain/authentication" do
  #   if cobot_client.check_in(params[:subdomain], params[:email], params[:password])
  #     status 204
  #   else
  #     status 403
  #   end
  # end

  get '/health' do
    status 200
  end

  get '/' do
    erb :home
  end

  # get "/spaces/:subdomain/users/:email" do
  #   membership = @space.membership(params[:email])
  #   if membership && (membership[:canceled_to].nil? || Date.parse(membership[:canceled_to]).future?)
  #     {
  #       name: membership[:address][:name],
  #       company: membership[:address][:company],
  #       plan: membership[:plan][:name],
  #       email: membership[:user][:email],
  #       expiration: membership[:canceled_to] && Time.parse("#{membership[:canceled_to]} 00:00:00 +0000").to_i,
  #       photo: membership[:picture]
  #     }.to_json
  #   else
  #     [404, {error: 'No user found.'}.to_json]
  #   end
  # end

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
