class Influencers::DownloadMediaJob < ApplicationJob
  queue_as :low

  CACHE_DIR = Rails.root.join('tmp/influencer_images')

  def perform(profile_id)
    profile = InfluencerProfile.find(profile_id)

    urls = collect_media_urls(profile)
    urls.each { |url| cache_image(url) }
  end

  private

  def collect_media_urls(profile)
    urls = [profile.profile_picture_url].compact_blank
    urls.concat(thumbnail_urls(profile.recent_reels))
    urls.concat(thumbnail_urls(profile.recent_posts))
    urls.uniq
  end

  def thumbnail_urls(items)
    (items || []).filter_map { |item| item['thumbnail_url'].presence }
  end

  def cache_image(url)
    cache_key = Digest::SHA256.hexdigest(url)
    cache_path = CACHE_DIR.join("#{cache_key}.jpg")
    return if File.exist?(cache_path)

    uri = URI.parse(url)
    return unless uri.is_a?(URI::HTTPS)

    response = Net::HTTP.get_response(uri)
    return unless response.is_a?(Net::HTTPSuccess)

    FileUtils.mkdir_p(CACHE_DIR)
    File.binwrite(cache_path, response.body)
  rescue URI::InvalidURIError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED => e
    Rails.logger.warn("[DownloadMediaJob] Failed to cache #{url}: #{e.message}")
  end
end
