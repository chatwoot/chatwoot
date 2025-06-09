require 'open-uri'
require 'tempfile'

class Integrations::Shopee::Uploader < Integrations::Shopee::Base
  VIDEO_LIMIT = 30 * 1024 * 1024 # 30 MB
  IMAGE_LIMIT = 10 * 1024 * 1024 # 10 MB
  SAFE_LOOP_LIMIT = 10 # Prevent infinite loops

  def upload_image(url)
    auth_client
      .body(file: download_image(url))
      .post('/api/v2/sellerchat/upload_image')
      .dig('response', 'url').presence || raise("Image upload failed for URL: #{url}")
  rescue StandardError => e
    raise "Failed to upload image from #{url}: #{e.message}"
  end

  def upload_video(url)
    vid = auth_client
          .body(file: download_video(url))
          .post('/api/v2/sellerchat/upload_video')
          .dig('response', 'vid').presence || raise("Video upload failed for URL: #{url}")

    video_info = get_video(vid)
    {
      vid: vid,
      video_url: video_info.dig('video').presence || raise("Video URL not found for vid: #{vid}"),
      thumb_url: video_info.dig('thumbnail').presence,
      thumb_width: video_info.dig('width').presence,
      thumb_height: video_info.dig('height').presence,
      duration_seconds: video_info.dig('duration').to_i / 1_000 # Convert milliseconds to seconds
    }
  rescue StandardError => e
    raise "Failed to upload video from #{url}: #{e.message}"
  end

  private

  def get_video(vid)
    attempts = 0
    loop do
      response = _get_video_status(vid)
      return response if response['status'] == 'successful'
      raise("Video upload failed: #{response.to_json}") if attempts >= SAFE_LOOP_LIMIT

      sleep(3) # Wait before retrying each 3 seconds
      attempts += 1
    end
  end

  def _get_video_status(vid)
    auth_client
      .query(vid: vid)
      .get('/api/v2/sellerchat/get_video_upload_result')
      .dig('response')
  end

  def download_video(url)
    Down.download(url, max_size: VIDEO_LIMIT)
  end

  def download_image(url)
    Down.download(url, max_size: IMAGE_LIMIT)
  end
end
