class Trend
  GOOGLE      = 'Google'
  TWITTER     = 'Twitter'
  TRENDSPOTTR = 'Trendspottr'

  def self.trends(user, source, country = nil, woeid = nil, query = nil)
    case source
      when Trend::GOOGLE then self.google
      when Trend::TWITTER then self.twitter(user, country, woeid)
      when Trend::TRENDSPOTTR then self.trendspottr(query)
      else []
    end
  end

  def self.twitter(user, country = nil, woeid = nil)
    trend_locations = user.twitter.trend_locations
    global          = trend_locations.map { |location| location.country }.unshift('Worldwide').uniq.map { |trend_country| {:name => trend_country, :value => trend_country} }
    by_location     = []
    local_trends    = []

    # get all of the locations in a country, excluding the country that the location belongs to
    if country.present?
      by_location = trend_locations.select { |location| location.country == country and location.name != country }.map { |location| {:name => location.name, :value => location.woeid} }
    end

    if woeid.present?
      # get the trends for a region
      local_trends = user.twitter.local_trends(woeid)
    elsif country.present?
      # if just the country is present then get the trends for that country without a region
      country_info  = trend_locations.select { |location| location.name == country }.map { |location| {:name => location.name, :value => location.woeid} }.first
      local_trends  = user.twitter.local_trends(country_info[:value])
    end

    [global.sort_by { |trend| trend[:name] }.reverse, by_location.sort_by { |trend| trend[:name] }.reverse, local_trends.map { |trend| {:name => trend.name, :value => trend.name} } ]
  end

  def self.google
    doc   = Nokogiri::XML(Kernel.open('http://www.google.com/trends/hottrends/atom/hourly'))
    cdata = Nokogiri::XML(doc.search('content').text)

    [[], [], cdata.xpath('//li').map{ |item| {:name => item.text, :value => item.text} }]
  end

  def self.trendspottr(query, location = 'twitter')
    return [[], [], []] if query.nil?

    response      = HTTParty.get('http://trendspottr.com/api/v1.1/search.php',
                             { :query => { :q => query, :w => location }, :basic_auth => {:username => ENV['TRENDSPOTTR_USERNAME'], :password => ENV['TRENDSPOTTR_PASSWORD'] } })
    body          = JSON::parse(response.body) || {}
    results_json  = body['results'] || {}
    trends        = []

    results_json.each do |trend_type, trend_array|
      trend_array.each do |trend|
        if trend_type == 'links'
          begin
            uri = URI.parse(trend['value'])
          rescue URI::InvalidURIError
            uri = nil
          end

          if uri.present? and uri.host != 't.co'
            bitly = Bitly::Client.new(uri.to_s)

            bitly.shorten and (trend['value'] = bitly.shortened_url)
          end
        end
        trends << { :type   => trend_type,
                    :name   => trend['value'],
                    :value  => trend['value'],
                    :weight => trend['weight'] }
      end
    end

    trends.group_by { |trend| trend[:type] }.select { |trend_type, trend_array| trend_type == 'links' }

    [[], [], trends]
  end

  def self.trendspottr_popular_topics
    TrendspottrTopic.select(:name).map(&:name)
  end

  def self.trendspottr_popular_searches
    TrendspottrSearch.select(:name).map(&:name)
  end
end

