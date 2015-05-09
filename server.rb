require 'sinatra'
require 'google/api_client'
require 'json'

enable :sessions
def user_credentials
  @authorization ||= (
    auth = settings.api_client.authorization.dup
    auth.redirect_uri = to('/oauth2callback')
    auth.update_token!(session)
    auth
  )
end

def oauth_req?(path)
  path =~ /^\/oauth2/
end

def valid_users
  Dir.glob("data/*").map { |f| f.split('/').last + "@gmail.com" }
end

configure do
  client = Google::APIClient.new
  client.authorization.client_id = ENV["CLIENT_ID"]
  client.authorization.client_secret = ENV["CLIENT_SECRET"]
  client.authorization.scope = 'email'
  oauth2_api = client.discovered_api('plus')
  set :api_client, client
  set :oauth2_api, oauth2_api
  set :bind, '0.0.0.0'
  set :port, 4566
  set :valid_users, valid_users
  set :public_folder, File.dirname(__FILE__) + '/public'
end

before do
  unless user_credentials.access_token || oauth_req?(request.path_info)
    redirect to('/oauth2authorize')
  end
  if user_credentials.access_token && !oauth_req?(request.path_info)
    result = settings.api_client.execute(:api_method => settings.oauth2_api.people.get,
                                         :parameters => {'userId' => 'me'},
                                         :authorization => user_credentials)
    session[:user] = result.data.to_hash
    is_valid = session[:user]["emails"].any? do |email|
      valid_users.include? email["value"]
    end
    unless is_valid
      halt "Access Denied"
    end
  end
end

after do
  session[:access_token] = user_credentials.access_token
  session[:refresh_token] = user_credentials.refresh_token
  session[:expires_in] = user_credentials.expires_in
  session[:issued_at] = user_credentials.issued_at
end

get '/oauth2authorize' do
  redirect user_credentials.authorization_uri.to_s, 303
end

get '/oauth2callback' do
  user_credentials.code = params[:code] if params[:code]
  user_credentials.fetch_access_token!
  redirect to('/')
end

get '/data' do
  email = session[:user]["emails"].find do |email|
    valid_users.include? email["value"]
  end
  File.read("data/#{email["value"].split('@').first}")
end

post '/data' do
  data = request.body.read
end

get '/' do
  content_type :html
  File.read(File.join('public', 'index.html'))
end

