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
                    :contact => 8, :ig_reel => 9 }

  def push_event_data
    return unless file_type
    return base_data.merge(location_metadata) if file_type.to_sym == :location
    return base_data.merge(fallback_data) if file_type.to_sym == :fallback
    return base_data.merge(contact_metadata) if file_type.to_sym == :contact

    base_data.merge(file_metadata)
  end

  # NOTE: the URl returned does a 301 redirect to the actual file
  def file_url
    file.attached? ? url_for(file) : ''
  end

  # NOTE: for External services use this methods since redirect doesn't work effectively in a lot of cases
  def download_url
    ActiveStorage::Current.url_options = Rails.application.routes.default_url_options if ActiveStorage::Current.url_options.blank?
    file.attached? ? file.blob.url : ''
  end

  def thumb_url
    if file.attached? && file.representable?
      url_for(file.representation(resize_to_fill: [250, nil]))
    else
      ''
    end
  end

  private

  def file_metadata
    metadata = {
      extension: extension,
      data_url: file_url,
      thumb_url: thumb_url,
      file_size: file.byte_size,
      width: file.metadata[:width],
      height: file.metadata[:height]
    }

    metadata[:data_url] = metadata[:thumb_url] = external_url if message.inbox.instagram?
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
end
