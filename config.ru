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

use Rack::Static, :urls => ["/css", "/images", "/js", "favicon.ico"], :root => "public"

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
             authorize_url(:redirect_uri => redirect_uri, :state => 1))
  end

  get '/auth/gowalla/callback' do
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

protected

  def client    
    api_key = ENV['API_KEY'] || '63914094b32346229c81694bec3ffc22'
    api_secret = ENV['API_SECRET'] || 'cb74c1e2f66c4c289fde2939bf6a6433'
    options = {
      :site => ENV['SITE'] || 'https://api.gowalla.com',
      :authorize_url => ENV['AUTHORIZE_URL'] || 'http://api.gowalla.com/api/oauth/new',
      :access_token_url => ENV['TOKEN_URL'] || 'http://api.gowalla.com/api/oauth/token'
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

end

run App
