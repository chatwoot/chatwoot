# Downloads and attaches avatar images from a URL.
# Notes:
# - For contact objects, we use `additional_attributes` to rate limit the
#   job and track state.
# - We save the hash of the synced URL after a successful attach, so an
#   unchanged asset is not downloaded again while a failed download is
#   retried on a later sync.
# - A 1 minute rate limit window is enforced via `last_avatar_sync_at`.
class Avatar::AvatarFromUrlJob < ApplicationJob
  self.enqueue_after_transaction_commit = true

  include UrlHelper
  queue_as :purgable

  ALLOWED_CONTENT_TYPES = Avatarable::ALLOWED_AVATAR_CONTENT_TYPES
  # Some providers (e.g. Telegram Bot API file URLs) serve images as a generic
  # binary stream. These are accepted for download and the real type is
  # sniffed from the file contents before attaching.
  GENERIC_BINARY_CONTENT_TYPE = 'application/octet-stream'.freeze
  MAX_DOWNLOAD_SIZE = 15.megabytes
  RATE_LIMIT_WINDOW = 1.minute

  def perform(avatarable, avatar_url)
    return unless syncable_avatar?(avatarable, avatar_url)

    attached = fetch_and_attach_avatar(avatarable, avatar_url)
  rescue SafeFetch::HttpError => e
    log_http_error(avatar_url, e)
  rescue SafeFetch::Error => e
    Rails.logger.error "AvatarFromUrlJob error for #{avatar_url}: #{e.class} - #{e.message}"
  ensure
    update_avatar_sync_attributes(avatarable, avatar_url, attached: attached == true)
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
      allowed_content_types: ALLOWED_CONTENT_TYPES + [GENERIC_BINARY_CONTENT_TYPE]
    ) do |avatar_file|
      attach_avatar(avatarable, avatar_file)
    end
  end

  def attach_avatar(avatarable, avatar_file)
    raise SafeFetch::FetchError, 'Invalid file' unless valid_file?(avatar_file)

    content_type = resolved_content_type(avatar_file)
    unless ALLOWED_CONTENT_TYPES.include?(content_type)
      raise SafeFetch::UnsupportedContentTypeError, "content-type not allowed: #{content_type}"
    end

    avatarable.avatar.attach(
      io: avatar_file.tempfile,
      filename: avatar_file.original_filename,
      content_type: content_type
    ).present?
  end

  # For a generic binary response, detect the real type from the file's magic
  # bytes so non-image payloads are rejected and images keep a precise type.
  def resolved_content_type(avatar_file)
    return avatar_file.content_type unless avatar_file.content_type == GENERIC_BINARY_CONTENT_TYPE

    tempfile = avatar_file.tempfile
    tempfile.rewind
    Marcel::MimeType.for(tempfile)
  ensure
    tempfile&.rewind
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

  def update_avatar_sync_attributes(avatarable, avatar_url, attached: false)
    # Only Contacts have sync attributes persisted
    return unless avatarable.is_a?(Contact)
    return if avatar_url.blank?

    additional_attributes = avatarable.additional_attributes || {}
    # Always record the attempt so the rate limit window applies.
    additional_attributes['last_avatar_sync_at'] = Time.current.iso8601
    # Only remember the URL once its avatar is attached, so failures are retried.
    additional_attributes['avatar_url_hash'] = generate_url_hash(avatar_url) if attached

    # Persist without triggering validations that may fail due to avatar file checks
    avatarable.update_columns(additional_attributes: additional_attributes) # rubocop:disable Rails/SkipsModelValidations
  end

  def valid_file?(file)
    return false if file.original_filename.blank?

    true
  end
end
