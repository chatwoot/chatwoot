# == Schema Information
#
# Table name: attachments
#
#  id               :integer          not null, primary key
#  coordinates_lat  :float            default(0.0)
#  coordinates_long :float            default(0.0)
#  extension        :string
#  external_url     :string
#  fallback_title   :string
#  file_type        :integer          default("image")
#  meta             :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :integer          not null
#  message_id       :integer          not null
#
# Indexes
#
#  index_attachments_on_account_id  (account_id)
#  index_attachments_on_message_id  (message_id)
#

class Attachment < ApplicationRecord
  include Rails.application.routes.url_helpers

  ACCEPTABLE_FILE_TYPES = %w[
    text/csv text/plain text/rtf text/xml
    application/json application/pdf
    application/xml
    application/zip application/x-7z-compressed application/vnd.rar application/x-tar
    application/msword application/vnd.ms-excel application/vnd.ms-powerpoint application/rtf
    application/vnd.oasis.opendocument.text
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/x-pkcs12 application/pkcs12
  ].freeze
  ACCEPTABLE_FILE_EXTENSIONS = %w[pfx xml].freeze
  GENERIC_FILE_CONTENT_TYPES = %w[application/octet-stream].freeze
  belongs_to :account
  belongs_to :message
  has_one_attached :file
  before_save :set_extension
  validate :acceptable_file
  # Off by default on purpose. Only the paths where we compose a message and are about to send it
  # turn this on, because a refusal on an ingested attachment raises inside the provider webhook
  # and loses the whole message instead of storing an odd one.
  attr_accessor :refuse_empty_file

  validate :file_is_not_empty, if: :refuse_empty_file
  validates :external_url, length: { maximum: Limits::URL_LENGTH_LIMIT }
  enum :file_type, { image: 0, audio: 1, video: 2, file: 3, location: 4, fallback: 5, share: 6, story_mention: 7,
                     contact: 8, ig_reel: 9, ig_post: 10, ig_story: 11, embed: 12 }

  METADATA_BUILDERS = {
    location: :location_metadata, fallback: :fallback_data, contact: :contact_metadata,
    audio: :audio_metadata, video: :video_metadata, embed: :embed_data
  }.freeze

  def push_event_data
    return unless file_type

    base_data.merge(metadata_for_file_type)
  end

  # NOTE: the URl returned does a 301 redirect to the actual file
  def file_url
    file.attached? ? url_for(file) : ''
  end

  # NOTE: for External services use this methods since redirect doesn't work effectively in a lot of cases
  def download_url
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    return '' unless file.attached?

    normalize_opus_blob_content_type!
    file.blob.url
  end

  # Blobs written before the identification was corrected still carry audio/opus, which is the
  # type WhatsApp Cloud rejects with 131053. Catch them the next time the file is handed to an
  # external service. New blobs never reach here: config/initializers/active_storage_opus_fix.rb
  # settles the type before the object is written.
  def normalize_opus_blob_content_type!
    blob = file.blob
    return unless blob.content_type == 'audio/opus'

    # update!, not update_column, because the point is the callback: ActiveStorage rewrites the
    # object's own Content-Type in the bucket on commit. Correcting only the column leaves the
    # stored object as audio/opus, and on GCS that metadata is what a reader gets, so the fix
    # would be invisible to the one service where it matters.
    blob.update!(content_type: 'audio/ogg')
  end

  def thumb_url
    return '' unless file.attached? && image?

    begin
      url_for(file.representation(resize_to_fill: [250, nil]))
    rescue ActiveStorage::UnrepresentableError => e
      Rails.logger.warn "Unrepresentable image attachment: #{id} (#{file.filename}) - #{e.message}"
      ''
    end
  end

  def with_attached_file?
    [:image, :audio, :video, :file].include?(file_type.to_sym)
  end

  private

  def metadata_for_file_type
    builder = METADATA_BUILDERS[file_type.to_sym]
    return send(builder) if builder

    file.attached? ? file_metadata : { data_url: external_url, thumb_url: '' }
  end

  def embed_data
    {
      data_url: external_url
    }
  end

  def audio_metadata
    audio_file_data = base_data.merge(file_metadata)
    audio_file_data.merge(
      {
        # Inline disposition so the player streams it instead of the browser downloading it; the
        # route follows whichever Active Storage delivery method the install configured.
        data_url: inline_storage_url,
        transcribed_text: meta&.[]('transcribed_text') || ''
      }
    )
  end

  # Same pair as audio: `file_url` carries no disposition, so a video is served as an
  # attachment and Safari refuses to play a `<video>` whose response says so. The MIME also
  # has to be in `content_types_allowed_inline`, or this URL is forced back to attachment.
  #
  # The two cases where the bytes are not ours keep the address they had: an attachment with
  # no file is one we only hold a link to, and an Instagram incoming message is served from
  # Meta's CDN on purpose.
  def video_metadata
    return { data_url: external_url, thumb_url: '' } unless file.attached?

    metadata = file_metadata
    return metadata if instagram_incoming_message?

    metadata.merge({ data_url: inline_storage_url })
  end

  def inline_storage_url
    return '' unless file.attached?

    # Through whichever route the installation configured (redirect, or proxy for S3/CORS setups),
    # the same way `url_for(file)` resolves it, but asking for inline: the audio and video players
    # cannot use a URL that is served as an attachment.
    Rails.application.routes.url_helpers.route_for(ActiveStorage.resolve_model_to_route, file, disposition: 'inline')
  end

  def file_metadata
    metadata = {
      extension: extension,
      content_type: file.content_type,
      data_url: file_url,
      thumb_url: thumb_url,
      file_size: file.byte_size,
      width: file.metadata[:width],
      height: file.metadata[:height]
    }

    metadata[:data_url] = metadata[:thumb_url] = external_url if instagram_incoming_message?
    metadata
  end

  def location_metadata
    {
      coordinates_lat: coordinates_lat,
      coordinates_long: coordinates_long,
      fallback_title: fallback_title,
      data_url: external_url
    }
  end

  def fallback_data
    {
      fallback_title: fallback_title,
      data_url: external_url
    }
  end

  def base_data
    {
      id: id,
      message_id: message_id,
      file_type: file_type,
      account_id: account_id,
      meta: meta || {}
    }
  end

  def contact_metadata
    {
      fallback_title: fallback_title,
      meta: meta || {}
    }
  end

  def instagram_incoming_message?
    return false unless message.incoming?

    return true if message.inbox.instagram_direct?

    message.inbox.instagram? && message.conversation&.additional_attributes&.dig('type') == 'instagram_direct_message'
  end

  def set_extension
    return unless file.attached?
    return if extension.present?

    self.extension = File.extname(file.filename.to_s).delete_prefix('.').presence
  end

  def should_validate_file?
    return false unless file.attached?
    # we are only limiting attachment types in case of website widget
    return false unless message.inbox.channel_type == 'Channel::WebWidget'

    true
  end

  # Separate from `acceptable_file`, which runs only on a web widget inbox: which *types* an inbox
  # accepts is a per-channel policy, while a file with no bytes is useless on every channel. Who
  # gets refused is decided by `refuse_empty_file`, not by the message type, and the flag lives in
  # memory only, so reloading a row that was stored before this existed never refuses it later.
  def file_is_not_empty
    return unless file.attached? && file.byte_size.to_i.zero?

    errors.add(:file, 'is empty')
  end

  def acceptable_file
    return unless should_validate_file?

    validate_file_size(file.byte_size)
    validate_file_content_type(file.content_type)
  end

  def validate_file_content_type(file_content_type)
    return if media_file?(file_content_type) || ACCEPTABLE_FILE_TYPES.include?(file_content_type)
    return if generic_file_content_type?(file_content_type) && ACCEPTABLE_FILE_EXTENSIONS.include?(file_extension)

    errors.add(:file, 'type not supported')
  end

  def validate_file_size(byte_size)
    limit_mb = GlobalConfigService.load('MAXIMUM_FILE_UPLOAD_SIZE', 40).to_i
    limit_mb = 40 if limit_mb <= 0

    errors.add(:file, 'size is too big') if byte_size > limit_mb.megabytes
  end

  def media_file?(file_content_type)
    file_content_type.to_s.start_with?('image/', 'video/', 'audio/')
  end

  def generic_file_content_type?(file_content_type)
    file_content_type.blank? || GENERIC_FILE_CONTENT_TYPES.include?(file_content_type)
  end

  def file_extension
    File.extname(file.filename.to_s).delete_prefix('.').downcase
  end
end

Attachment.include_mod_with('Concerns::Attachment')
