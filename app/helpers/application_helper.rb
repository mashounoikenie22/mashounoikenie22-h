module ApplicationHelper
  def twitter_auth_url
   '/auth/twitter'
  end

  def facebook_auth_url
    '/auth/facebook'
  end

  def youtube_auth_url
    '/auth/google'
  end

  def group_hash_by(hashes, group_by)
    return nil if hashes.nil?

    grouped = {}
    hashes.each do |element|
      key = element[group_by.to_sym]
      grouped[key] ||= []
      grouped[key] << element;
    end
    grouped
  end

  def large_content?
    if controller.controller_name == 'authorization' and controller.action_name == 'failure'
      return true
    elsif controller.controller_name == 'dashboard' and ['video_playback', 'index'].include?(controller.action_name)
      return true
    elsif controller.controller_name == 'content' and controller.action_name
      return true
    end

    false
  end

  def home?
    if controller.controller_name == 'authorization' and controller.action_name == 'failure'
      return true
    elsif controller.controller_name == 'content' and ['home'].include?(controller.action_name)
      return true
    end

    false
  end

  def conditional_div(condition, attributes, &block)
    if condition
      haml_tag :div, attributes, &block
    else
      haml_concat capture_haml(&block)
    end
  end

  def sanitize_twitter_screen_name(screen_name)
    screen_name.gsub(/[^0-9a-z\-\_]+/i, '')
  end

  protected
  def media_sources
    [{ :screen_name => '@ESPN', :name => 'ESPN', :image => 'espn.jpg' },
     { :screen_name => '@SportsCenter', :name => 'Sports Center', :image => 'sports-center.png' },
     { :screen_name => '@106andPark', :name => 'BET', :image => 'BET.jpg' },
     { :screen_name => '@CNN', :name => 'CNN', :image => 'cnn.png' },
     { :screen_name => '@FoxNews', :name => 'Fox News', :image => 'fox-news.png' },
     { :screen_name => '@BBCNews', :name => 'BBC News', :image => 'BBC-news.jpg' },
     { :screen_name => '@WeatherChannel', :name => 'Weather Channel', :image => 'weather-channel.png' },
     { :screen_name => '@Starbucks', :name => 'Starbucks', :image => 'starbucks.png' },
     { :screen_name => '@Google', :name => 'Google', :image => 'google.png' },
     { :screen_name => '@Amazon', :name => 'Amazon', :image => 'amazon.png' },
     { :screen_name => '@ConanOBrien', :name => 'Conan O\'Brien', :image => 'conan-obrien.jpg' },
     { :screen_name => '@JayLeno', :name => 'Jay Leno', :image => 'jay-leno.jpg' },
     { :screen_name => '@GMA', :name => 'Good Morning America', :image => 'gma.JPG' },
     { :screen_name => '@MTV', :name => 'MTV', :image => 'mtv.jpg' },
     { :screen_name => '@10onTop', :name => '10 on Top', :image => '10-on-top.jpg' }]
   end
end

