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

class App < Sinatra::Base

  set :sessions, true

  get '/' do
    if session[:access_token]
      redirect '/auth/gowalla/test'
    else
      "Why not authenticate with <a href=\'/auth/gowalla\'>Gowalla</a>?"
    end
  end

  get '/auth/gowalla' do
    redirect(client.web_server.
             authorize_url(:redirect_uri => redirect_uri, :state => 1))
  end

  get '/auth/gowalla/callback' do
    session[:access_token] = client.
      web_server.
      get_access_token(params[:code], :redirect_uri => redirect_uri).token

    if session[:access_token]
      redirect '/auth/gowalla/test'
    else
      "Error retrieving access token."
    end
  end

  get '/auth/gowalla/test' do
    if session[:access_token]
      connection = OAuth2::AccessToken.new(client, session[:access_token])
      headers = {'Accept' => 'application/json'}
      connection.get('/users/jw', {}, headers).inspect
    else
      redirect '/auth/gowalla'
    end
  end

  protected

  def client
    api_key = ENV['API_KEY'] || '2669aacbe4a44db7a0d0c8444eb2782f'
    api_secret = ENV['API_SECRET'] || 'a0fbd20e3a4e4b078f2ee159d4b3e29e'
    options = {
      :site => ENV['SITE'] || 'http://localhost:3000',
      :authorize_url => ENV['AUTHORIZE_URL'] || 'http://localhost:3000/api/oauth/new',
      :access_token_url => ENV['TOKEN_URL'] || 'http://localhost:3000/api/oauth/token'
    }
    OAuth2::Client.new(api_key, api_secret, options)
  end

  def redirect_uri
    uri = URI.parse(request.url)
    uri.path = '/auth/gowalla/callback'
    uri.query = nil
    uri.to_s
  end

end

run App
