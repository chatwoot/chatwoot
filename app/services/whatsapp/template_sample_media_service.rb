# The sample media a template ships with (`components[].example.header_handle[0]`) is hosted on Meta's
# own CDN, which answers 403 to Meta's media fetcher. Passing it as a `link` therefore fails every send
# with "131053 Media upload error", even though the very same URL downloads fine from anywhere else.
# Uploading the file to the media store once and addressing it by id sidesteps the fetch entirely.
class Whatsapp::TemplateSampleMediaService
  # Meta keeps uploaded media for 30 days; expire a little early so an id is never used past its life.
  CACHE_TTL = 25.days

  pattr_initialize [:channel!, :url!]

  def media_id
    Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { upload }
  end

  private

  # Keyed on the URL without its query, because Meta re-signs the handle on every template sync while
  # the file behind it stays the same. Keying on the full URL would re-upload the same media every time
  # the signature rotated.
  #
  # Scoped to the phone number rather than to the channel, because a media id belongs to the Cloud
  # account that uploaded it: reauthorizing an inbox swaps the phone number id while keeping the channel
  # record, and an id minted under the old account is not addressable by the new one.
  def cache_key
    path = Addressable::URI.parse(url).omit(:query, :fragment).to_s
    "whatsapp_template_sample_media/#{channel.provider_config['phone_number_id']}/#{Digest::SHA256.hexdigest(path)}"
  end

  def upload
    file = Down.download(url)
    channel.provider_service.upload_media(file, file.content_type)
  rescue Down::ClientError, Down::InvalidUrl => e
    # Only a 4xx (bar a rate limit) or a malformed URL is the media's own fault and worth failing the
    # message over. A 429, a timeout, a refused connection or a 5xx is the CDN having a bad minute:
    # those propagate so Sidekiq retries, instead of dropping the send for good over a blip.
    raise if rate_limited?(e)

    raise CustomExceptions::Whatsapp::MediaUploadError, "Could not download the template sample media: #{e.message}"
  ensure
    file&.close
    file&.unlink
  end

  def rate_limited?(error)
    error.is_a?(Down::ResponseError) && error.response&.code.to_i == 429
  end
end
