# == Schema Information
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
    text/csv text/plain text/rtf
    application/json application/pdf
    application/zip application/x-7z-compressed application/vnd.rar application/x-tar
    application/msword application/vnd.ms-excel application/vnd.ms-powerpoint application/rtf
    application/vnd.oasis.opendocument.text
    application/vnd.openxmlformats-officedocument.presentationml.presentation
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze
  belongs_to :account
  belongs_to :message
  has_one_attached :file
  validate :acceptable_file
  validates :external_url, length: { maximum: Limits::URL_LENGTH_LIMIT }
  enum file_type: { :image => 0, :audio => 1, :video => 2, :file => 3, :location => 4, :fallback => 5, :share => 6, :story_mention => 7,
                    :contact => 8, :ig_reel => 9, :ig_story => 10 }

  def push_event_data
    return unless file_type
    return base_data.merge(location_metadata) if file_type.to_sym == :location
    return base_data.merge(fallback_data) if file_type.to_sym == :fallback
    return base_data.merge(contact_metadata) if file_type.to_sym == :contact

    base_data.merge(file_metadata)
  end

  # NOTE: the URl returned does a 301 redirect to the actual file
  def file_url
    file.attached? && file.filename.present? && file.filename.to_s.present? ? url_for(file) : ''
  end

  # NOTE: for External services use this methods since redirect doesn't work effectively in a lot of cases
  def download_url
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    file.attached? ? file.blob.url : ''
  end

  def thumb_url
    if file.attached? && file.representable? && file.filename.present? && file.filename.to_s.present?
      url_for(file.representation(resize_to_fill: [250, nil]))
    else
      ''
    end
  end

  private

  # rubocop:disable Metrics/AbcSize
  def file_metadata
    metadata = {
      extension: extension,
      data_url: file_url,
      thumb_url: thumb_url,
      file_size: file.byte_size,
      width: file.metadata&.[](:width),
      height: file.metadata&.[](:height)
    }

    metadata[:data_url] = metadata[:thumb_url] = external_url if message.inbox.instagram? && message.sender_type == 'Contact'
    metadata[:data_url] = metadata[:thumb_url] = external_url if external_url && message.inbox.api?
    metadata
  end
  # rubocop:enable Metrics/AbcSize

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
      account_id: account_id
    }
  end

  def contact_metadata
    {
      fallback_title: fallback_title
    }
  end

  def should_validate_file?
    return unless file.attached?
    # we are only limiting attachment types in case of website widget
    return unless message.inbox.channel_type == 'Channel::WebWidget'

    true
  end

  def acceptable_file
    return unless should_validate_file?

    validate_file_size(file.byte_size)
    validate_file_content_type(file.content_type)
  end

  def validate_file_content_type(file_content_type)
    errors.add(:file, 'type not supported') unless media_file?(file_content_type) || ACCEPTABLE_FILE_TYPES.include?(file_content_type)
  end

  def validate_file_size(byte_size)
    errors.add(:file, 'size is too big') if byte_size > 40.megabytes
  end

  def media_file?(file_content_type)
    file_content_type.start_with?('image/', 'video/', 'audio/')
  end

  def merge_story_mention_image(metadata)
    if message.try(:content_attributes)[:image_type] == 'story_mention' && message.inbox.instagram?
      begin
        metadata = fetch_story_link(message, metadata)
      rescue Koala::Facebook::ClientError
        delete_instagram_story(message)
      end
    end

    metadata
  end

  def fetch_story_link(message, metadata)
    k = Koala::Facebook::API.new(message.inbox.channel.page_access_token)
    result = k.get_object(message.source_id, fields: %w[story]) || {}

    if result['story']['mention']['link'].blank?
      metadata[:data_url] = nil
      metadata[:thumb_url] = nil
      delete_instagram_story(message)
    else
      metadata = add_ig_story_data_url(metadata)
    end
    metadata
  end

  def delete_instagram_story(message)
    message.update(content: I18n.t('conversations.messages.instagram_deleted_story_content'))
    delete
  end

  def add_ig_story_data_url(metadata)
    metadata[:data_url] = external_url
    metadata[:thumb_url] = external_url
    metadata
  end
end
