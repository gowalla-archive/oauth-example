begin
  # Require preresolved locked gems
  require ::File.expand_path('.bundle/environment', __FILE__)
rescue LoadError
  # Fallback on resolving at runtime
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

require 'sinatra/base'
require 'oauth2'
require 'json'
require 'haml'

require 'open-uri'

require 'lib/helpers'

class App < Sinatra::Base

  set :sessions, true

  helpers do
    include Helpers
  end

  get '/' do
    redirect '/auth/gowalla' unless session[:access_token]
    
    @user = JSON.parse(connection.get('/users/me', {}, headers))  
    
    haml :index
  end

  get '/spots' do
    @lat = params[:lat].to_f
    @lng = params[:lng].to_f

    @spots = JSON.parse(open("http://api.gowalla.com/spots.json?lat=#{@lat}&lng=#{@lng}&limit=10").read)["spots"]

    haml :spots
  end
  
  post '/spots/:id/check-in' do
    content_type :json
    
    @checkin = JSON.parse(connection.post('/checkins', {
      :spot_id => params[:id],
      :lat => params[:lat],
      :lng => params[:lng]
    }, headers))
    
    @checkin.to_json
  end
  
# Authentication

  get '/auth/gowalla' do
    redirect(client.web_server.
             authorize_url(:redirect_uri => redirect_uri, :scope => 'read-write'))
  end

  get '/auth/gowalla/callback' do
    begin
      response = client.
        web_server.
        get_access_token(params[:code], :redirect_uri => redirect_uri)
      session[:access_token] = response.token
      session[:refresh_token] = response.refresh_token

      if session[:access_token]
        redirect '/'
      else
        "Error retrieving access token."
      end
    rescue OAuth2::HTTPError => e
      e.response.body
    end
  end

  get '/auth/gowalla/refresh' do
    if session[:refresh_token]
      # This doesn't work. Patch oauth2?
      response = client.
        web_server.
        get_access_token(nil, :refresh_token => session[:refresh_token], :type => 'refresh_token')
      session[:access_token] = response.token
      session[:refresh_token] = response.refresh_token
      puts response.refresh_token
    else
      redirect '/auth/gowalla'
    end
  end

  error OAuth2::HTTPError do
    reset
  end
  
  error OAuth2::AccessDenied do
    reset
  end

protected

  def client
    api_key    = ENV['API_KEY']
    api_secret = ENV['API_SECRET']
    site       = ENV['SITE'] || 'https://api.gowalla.com'
    options = {
      :site => site,
      :authorize_url => site.dup << '/api/oauth/new',
      :access_token_url => site.dup << '/api/oauth/token'
    }
    OAuth2::Client.new(api_key, api_secret, options)
  end
  
  def connection
    OAuth2::AccessToken.new(client, session[:access_token], session[:refresh_token])
  end

  def headers
    {'Accept' => 'application/json'}
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = '/auth/gowalla/callback'
    uri.query = nil
    uri.to_s
  end

  # An error from Gowalla most likely means our token is bad. Delete it
  # and re-authorize.
  def reset
    session.delete(:access_token)
    session.delete(:refresh_token)
    redirect('/auth/gowalla')
  end
end

use Rack::Static, :urls => ["/css", "/images", "/js", "favicon.ico"], :root => "public"
run App
