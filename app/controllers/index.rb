get '/' do
  erb :index
end

get '/sign_in' do
  # the `request_token` method is defined in `app/helpers/oauth.rb`
  redirect request_token.authorize_url
end

get '/sign_out' do
  session.clear
  redirect '/'
end

get '/auth' do
  # the `request_token` method is defined in `app/helpers/oauth.rb`
  @access_token = request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
  # our request token is only valid until we use it to get an access token, so let's delete it from our session
  session.delete(:request_token)
  # at this point in the code is where you'll need to create your user account and store the access token
  user = User.find_or_create_by(username: @access_token.params[:screen_name])
  user.oauth_token = @access_token.token
  user.oauth_secret = @access_token.secret
  user.save
  session[:user_id] = user.id
  erb :index
end

post '/tweet' do
  ## reset connection with the user's tokens
  tweeting_user = User.find(session[:user_id])
  env_config = YAML.load_file(APP_ROOT.join('config', 'twitter.yaml'))
  env_config.each do |key, value|
    ENV[key] = value
  end
  client = Twitter::REST::Client.new do |config|
    config.consumer_key = ENV['TWITTER_KEY']
    config.consumer_secret = ENV['TWITTER_SECRET']
    config.access_token = tweeting_user.oauth_token
    config.access_token_secret = tweeting_user.oauth_secret
  end
  @success = client.update(params[:tweet])
  erb :index
end
