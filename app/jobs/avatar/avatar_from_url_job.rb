# Downloads and attaches avatar images from a URL.
# Notes:
# - For contact objects, we use `additional_attributes` to rate limit the
#   job and track state. Sync
#   attributes are only persisted when an actual avatar update occurs.
# - We save the hash of the synced URL to retrigger downloads only when
#   there is a change in the underlying asset.
# - A 1 minute rate limit window is enforced via `last_avatar_sync_at`.
class Avatar::AvatarFromUrlJob < ApplicationJob
  include UrlHelper
  queue_as :purgable

  MAX_DOWNLOAD_SIZE = 15 * 1024 * 1024
  RATE_LIMIT_WINDOW = 1.minute

  def perform(avatarable, avatar_url)
    return unless avatarable.respond_to?(:avatar)
    return unless url_valid?(avatar_url)

    return unless should_sync_avatar?(avatarable, avatar_url)

    avatar_file = Down.download(avatar_url, max_size: MAX_DOWNLOAD_SIZE)
    return unless valid_image?(avatar_file)

    avatarable.avatar.attach(
      io: avatar_file,
      filename: avatar_file.original_filename,
      content_type: avatar_file.content_type
    )

    # Persist sync attributes only when an actual update happens
    update_avatar_sync_attributes(avatarable, avatar_url)
  rescue Down::NotFound, Down::Error => e
    Rails.logger.error "AvatarFromUrlJob error for #{avatar_url}: #{e.class} - #{e.message}"
  end

  private

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
