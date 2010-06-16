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

$access_token = nil

class App < Sinatra::Base

  get '/' do
    "Why not authenticate with <a href=\'/auth/gowalla\'>Gowalla</a>?"
  end

  get '/auth/gowalla' do
    redirect(client.web_server.
             authorize_url(:redirect_uri => redirect_uri, :state => 1))
  end

  get '/auth/gowalla/callback' do
    $access_token = client.
      web_server.
      get_access_token(params[:code], :redirect_uri => redirect_uri)

    redirect '/auth/gowalla/test'
  end

  get '/auth/gowalla/test' do
    $access_token.get('/api/oauth/echo').to_s
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
