# Downloads and attaches avatar images from a URL.
# Notes:
# - For contact objects, we use `additional_attributes` to rate limit the
#   job and track state.
# - We save the hash of the synced URL to retrigger downloads only when
#   there is a change in the underlying asset.
# - A 1 minute rate limit window is enforced via `last_avatar_sync_at`.
class Avatar::AvatarFromUrlJob < ApplicationJob
  include UrlHelper
  queue_as :purgable

  ALLOWED_CONTENT_TYPES = Avatarable::ALLOWED_AVATAR_CONTENT_TYPES
  MAX_DOWNLOAD_SIZE = 15.megabytes
  RATE_LIMIT_WINDOW = 1.minute

  def perform(avatarable, avatar_url)
    return unless syncable_avatar?(avatarable, avatar_url)

    fetch_and_attach_avatar(avatarable, avatar_url)
  rescue SafeFetch::HttpError => e
    log_http_error(avatar_url, e)
  rescue SafeFetch::Error => e
    Rails.logger.error "AvatarFromUrlJob error for #{avatar_url}: #{e.class} - #{e.message}"
  ensure
    update_avatar_sync_attributes(avatarable, avatar_url)
  end

  private

  def syncable_avatar?(avatarable, avatar_url)
    avatarable.respond_to?(:avatar) &&
      url_valid?(avatar_url) &&
      should_sync_avatar?(avatarable, avatar_url)
  end

  def fetch_and_attach_avatar(avatarable, avatar_url)
    SafeFetch.fetch(
      avatar_url,
      max_bytes: MAX_DOWNLOAD_SIZE,
      allowed_content_type_prefixes: [],
      allowed_content_types: ALLOWED_CONTENT_TYPES
    ) do |avatar_file|
      attach_avatar(avatarable, avatar_file)
    end
  end

  def attach_avatar(avatarable, avatar_file)
    raise SafeFetch::FetchError, 'Invalid file' unless valid_file?(avatar_file)

    avatarable.avatar.attach(
      io: avatar_file.tempfile,
      filename: avatar_file.original_filename,
      content_type: avatar_file.content_type
    )
  end

  def log_http_error(avatar_url, error)
    if error.message.start_with?('404')
      Rails.logger.info "AvatarFromUrlJob: avatar not found at #{avatar_url}"
    else
      Rails.logger.error "AvatarFromUrlJob error for #{avatar_url}: #{error.class} - #{error.message}"
    end
  end

  def should_sync_avatar?(avatarable, avatar_url)
    # Only Contacts are rate-limited and hash-gated.
    return true unless avatarable.is_a?(Contact)

    attrs = avatarable.additional_attributes || {}

    return false if within_rate_limit?(attrs)
    return false if duplicate_url?(attrs, avatar_url)

    true
  end

  def within_rate_limit?(attrs)
    ts = attrs['last_avatar_sync_at']
    return false if ts.blank?

    Time.zone.parse(ts) > RATE_LIMIT_WINDOW.ago
  end

  def duplicate_url?(attrs, avatar_url)
    stored_hash = attrs['avatar_url_hash']
    stored_hash.present? && stored_hash == generate_url_hash(avatar_url)
  end

  def generate_url_hash(url)
    Digest::SHA256.hexdigest(url)
  end

  def update_avatar_sync_attributes(avatarable, avatar_url)
    # Only Contacts have sync attributes persisted
    return unless avatarable.is_a?(Contact)
    return if avatar_url.blank?

    additional_attributes = avatarable.additional_attributes || {}
    additional_attributes['last_avatar_sync_at'] = Time.current.iso8601
    additional_attributes['avatar_url_hash'] = generate_url_hash(avatar_url)

    # Persist without triggering validations that may fail due to avatar file checks
    avatarable.update_columns(additional_attributes: additional_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  def valid_file?(file)
    return false if file.original_filename.blank?

    true
  end
end
