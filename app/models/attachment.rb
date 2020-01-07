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

require 'uri'
require 'open-uri'
class Attachment < ApplicationRecord
  include Rails.application.routes.url_helpers
  belongs_to :account
  belongs_to :message
  has_one_attached :file

  enum file_type: [:image, :audio, :video, :file, :location, :fallback]

  def push_event_data
    return base_data.merge(location_metadata) if file_type.to_sym == :location
    return base_data.merge(fallback_data) if file_type.to_sym == :fallback

    base_data.merge(file_metadata)
  end

  private

  def file_metadata
    {
      extension: extension,
      data_url: file_url,
      thumb_url: file.try(:thumb).try(:url) # will exist only for images
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

  def file_url
    file.attached? ? url_for(file) : ''
  end
end
