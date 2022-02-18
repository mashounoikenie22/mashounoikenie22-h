class CacheTrendspottrPopularTrends
  @queue = :cache_trendspottr_popular_trends_queue
  
  def self.perform
    popular_topics    = []
    popular_searches  = []
    
    doc = Nokogiri::XML(Kernel.open('http://trendspottr.com/index.php?q=technology'))
    
    count = 1
    doc.css('html body div.main_container div#side_bar div#side_bar_popular_categories ul.side_bar_list').each do |side_bar_list|
      break if count % 3 == 0
      trends = popular_topics if count == 1
      trends = popular_searches if count == 2

      side_bar_list.css('li.side_bar_nav a').each do |link|
        trends << link.content
      end

      count += 1
    end

    ActiveRecord::Base.transaction do
      TrendspottrTopic.destroy_all
      popular_topics.each { |topic| TrendspottrTopic.new(:name => topic).save } 
    end
    
    ActiveRecord::Base.transaction do
      TrendspottrSearch.destroy_all
      popular_searches.each { |search| TrendspottrSearch.new(:name => search).save }
    end
  end
end
