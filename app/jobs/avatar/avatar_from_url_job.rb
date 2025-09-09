class Avatar::AvatarFromUrlJob < ApplicationJob
  queue_as :purgable

  def perform(avatarable, avatar_url)
    return unless avatarable.respond_to?(:avatar)
    return unless valid_url?(avatar_url)
    return unless should_sync_avatar?(avatarable, avatar_url)

    avatar_file = Down.download(
      avatar_url,
      max_size: 15 * 1024 * 1024
    )
    if valid_image?(avatar_file)
      avatarable.avatar.attach(io: avatar_file, filename: avatar_file.original_filename,
                               content_type: avatar_file.content_type)
      update_avatar_sync_attributes(avatarable, avatar_url)
    end
  rescue Down::NotFound, Down::Error => e
    Rails.logger.error "Exception: invalid avatar url #{avatar_url} : #{e.message}"
  end

  private

  def valid_url?(url)
    return false if url.blank?

    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end

  def should_sync_avatar?(avatarable, avatar_url)
    # Rate limiting and URL hash comparison only for contacts (which have additional_attributes)
    if avatarable.respond_to?(:additional_attributes) && avatarable.additional_attributes.present?
      # Check if we should skip due to rate limiting (30 minutes)
      last_sync_time = avatarable.additional_attributes['last_avatar_sync_at']
      if last_sync_time.present?
        last_sync = Time.zone.parse(last_sync_time)
        return false if last_sync > 30.minutes.ago
      end

      # Check if URL hash has changed
      current_url_hash = generate_url_hash(avatar_url)
      stored_url_hash = avatarable.additional_attributes['avatar_url_hash']

      # Skip if URL hash is the same (URL hasn't changed)
      return false if stored_url_hash == current_url_hash
    end

    true
  end

  def generate_url_hash(url)
    Digest::SHA256.hexdigest(url)
  end

  def update_avatar_sync_attributes(avatarable, avatar_url)
    # Only update sync attributes for contacts (which have additional_attributes)
    return unless avatarable.respond_to?(:additional_attributes)

    additional_attributes = avatarable.additional_attributes || {}
    additional_attributes['last_avatar_sync_at'] = Time.current.iso8601
    additional_attributes['avatar_url_hash'] = generate_url_hash(avatar_url)

    avatarable.update(additional_attributes: additional_attributes)
  end

  def valid_image?(file)
    return false if file.original_filename.blank?

    # TODO: check if the file is an actual image

    true
  end
end
