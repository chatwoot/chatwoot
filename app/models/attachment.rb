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
  include Attachmentable

  belongs_to :account
  belongs_to :message
  validates :external_url, length: { maximum: Limits::URL_LENGTH_LIMIT }

  def push_event_data
    return unless file_type
    return base_data.merge(location_metadata) if file_type.to_sym == :location
    return base_data.merge(fallback_data) if file_type.to_sym == :fallback
    return base_data.merge(contact_metadata) if file_type.to_sym == :contact

    base_data.merge(file_metadata)
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

    metadata[:data_url] = metadata[:thumb_url] = external_url if message.instagram_story_mention?
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
end
