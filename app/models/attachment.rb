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

  enum file_type: [:image, :audio, :video, :file, :location, :fallback]

  def push_event_data
    return unless file_type
    return base_data.merge(location_metadata) if file_type.to_sym == :location
    return base_data.merge(fallback_data) if file_type.to_sym == :fallback

    base_data.merge(file_metadata)
  end

  def file_url
    file.attached? ? url_for(file) : ''
  end

  def thumb_url
    if file.attached? && file.representable?
      url_for(file.representation(resize: '250x250'))
    else
      ''
    end
  end

  private

  def file_metadata
    {
      extension: extension,
      data_url: file_url,
      thumb_url: thumb_url
    }
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
