class VideoTransfer
  @queue = :video_transfer_queue
  
  def self.perform(out_id)
    @out   = Out.find(out_id)
    uri   = construct_nimbb_download_uri(@out)
    path  = "/tmp/#{@out.video.id}.#{ENV['NIMBB_VIDEO_FORMAT']}"
    
    download_nimbb_video(path, uri)
    transfer_nimbb_video_to_youtube(@out, path)
  end
  
  def self.construct_nimbb_download_uri(out)
    url = ENV['NIMBB_VIDEO_DOWNLOAD_URI']
    url += "?&key=#{ENV['NIMBB_PUBLIC_KEY']}"
    url += "&code=#{ENV['NIMBB_PRIVATE_KEY']}"
    url += "&guid=#{out.video.guid}"
    url += "&format=#{ENV['NIMBB_VIDEO_FORMAT']}"
  end
  
  def self.download_nimbb_video(path, uri)
    File.open(path, 'wb') do |file|
      file << Kernel.open(uri).read
    end
  end
  
  def self.get_youtube_video_info(out)
    if out.video.youtube_id.present?
      begin
        return out.user.youtube.my_video(out.video.youtube_id)
      rescue UploadError
      end
    end
  end
  
  def self.upload_nimbb_video_to_youtube(out, path)
    response = nil
    File.open(path) do |file| 
      response              = out.user.youtube.video_upload(file, :title => out.video.name)
      out.video.youtube_id  = response.unique_id
      out.video.save!
    end
    response
  end
  
  def self.transfer_nimbb_video_to_youtube(out, path)
    begin
      authorization = out.user.authorizations.find_by_provider('google')
      response      = get_youtube_video_info(out)
      response      = upload_nimbb_video_to_youtube(out, path) if response.blank?

      send_out_to_facebook(out, response)
      send_out_to_twitter(out, response)
      
      out.pending = false
      out.save
    ensure
      File.delete(path)
    end
  end
  
  def self.replace_bitly_link(out, bitly)
    bitly.shorten
    out.content.split(' ').map { |item| item.gsub(/http:\/\/out.am\/.+/, bitly.shortened_url) }.join(' ')
  end
  
  protected
    def self.send_out_to_facebook(out, response)
      if out.facebook?
        bitly       = Bitly::Client.new('http://www.youtube.com/v/' << response.unique_id)
        out.content = replace_bitly_link(out, bitly)
        params      = {:link     => bitly.shortened_url, 
                       :source   => bitly.shortened_url, 
                       :picture  => response.thumbnails.last.url}
                         
        TweetEmitter.new(out.user, out).facebook_post(params)
      end
    end
    
    def self.send_out_to_twitter(out, response)
      if out.twitter?
        bitly       = Bitly::Client.new(response.player_url)
        out.content = replace_bitly_link(out, bitly)
                                 
        TweetEmitter.new(out.user, out).twitter_post
      end
    end
end
