# Downloads and attaches avatar images from a URL.
# Notes:
# - For contact objects, we use `additional_attributes` to rate limit the
#   job and track state.
# - We save the hash of the synced URL to retrigger downloads only when
#   there is a change in the underlying asset.
# - A 1 minute rate limit window is enforced via `last_avatar_sync_at`.
class Avatar::AvatarFromUrlJob < ApplicationJob
  self.enqueue_after_transaction_commit = true

  include UrlHelper
  queue_as :purgable

  ALLOWED_CONTENT_TYPES = Avatarable::ALLOWED_AVATAR_CONTENT_TYPES
  MAX_DOWNLOAD_SIZE = 15.megabytes
  RATE_LIMIT_WINDOW = 1.minute

  # `resolved_at` is when the caller obtained the URL. Without it the job cannot tell a
  # picture that was removed while it waited in the queue from one that was never there,
  # and it puts the deleted photo back until the next picture event.
  def perform(avatarable, avatar_url, resolved_at: nil)
    return unless syncable_avatar?(avatarable, avatar_url)
    return if superseded?(avatarable, resolved_at)

    attempt_download(avatarable, avatar_url)
    update_avatar_sync_attributes(avatarable, avatar_url)
  end

  private

  # The markers belong to whoever actually tried to download. They used to be stamped from an
  # `ensure`, which the early returns above run straight through: a job that downloaded nothing
  # would open a fresh rate-limit window and record a URL it never fetched as already synced, and
  # the job carrying the new picture was then thrown away as a duplicate.
  #
  # A download that was attempted and failed still counts, so a URL that is permanently broken
  # does not get retried on every event. An error that is not SafeFetch's propagates without
  # stamping, because the job will be retried and must not find itself already marked.
  def attempt_download(avatarable, avatar_url)
    fetch_and_attach_avatar(avatarable, avatar_url)
  rescue SafeFetch::HttpError => e
    log_http_error(avatar_url, e)
  rescue SafeFetch::Error => e
    Rails.logger.error "AvatarFromUrlJob error for #{avatar_url}: #{e.class} - #{e.message}"
  end

  # A removal recorded after the URL was resolved makes that URL a picture the contact
  # has already taken down. Only Contacts carry the marker, which is where this job
  # keeps its other two; a caller that does not date its URL keeps the old behaviour.
  def superseded?(avatarable, resolved_at)
    return false if resolved_at.blank? || !avatarable.is_a?(Contact)

    removed_at = (avatarable.additional_attributes || {})[Whatsapp::Session::AvatarSync::REMOVED_AT]
    return false if removed_at.blank?

    Time.zone.parse(removed_at) > Time.zone.parse(resolved_at)
  end

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

    dispatch_contact_update(avatarable)
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

    avatarable.update_avatar_sync_markers!(
      merge: {
        'last_avatar_sync_at' => Time.current.iso8601,
        'avatar_url_hash' => generate_url_hash(avatar_url)
      }
    )
  end

  def valid_file?(file)
    return false if file.original_filename.blank?

    true
  end

  def dispatch_contact_update(avatarable)
    return unless avatarable.is_a?(Contact)

    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONTACT_UPDATED,
      Time.zone.now,
      contact: avatarable
    )
  end
end
