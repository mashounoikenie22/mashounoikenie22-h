OmniAuth.config.full_host = 'http://localhost:3000' if not Rails.env.production?

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']
  provider :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET'],
           :scope => 'email, read_stream, publish_stream',
           :client_options => {:ssl => {:ca_file => '/usr/lib/ssl/certs/ca-certificates.crt'}}
  provider :google, ENV['YOUTUBE_CONSUMER_KEY'], ENV['YOUTUBE_CONSUMER_SECRET'], :scope => 'http://gdata.youtube.com'
end

Twitter.configure do |config|
  config.consumer_key = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret = ENV['TWITTER_CONSUMER_SECRET']
end

