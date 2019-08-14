require 'uri'
require 'open-uri'
class Attachment < ApplicationRecord
  belongs_to :account
  belongs_to :message
  mount_uploader :file, AttachmentUploader #used for images
  enum file_type: [:image, :audio, :video, :file, :location, :fallback]

  before_create :set_file_extension

  def push_event_data
    data = {
      id: id,
      message_id: message_id,
      file_type: file_type,
      account_id: account_id
    }
    if [:image, :file, :audio, :video].include? file_type.to_sym
      data.merge!({
        extension: extension,
        data_url: file_url,
        thumb_url: file.try(:thumb).try(:url) #will exist only for images
    })
    elsif :location == file_type.to_sym
      data.merge!({
        coordinates_lat: coordinates_lat,
        coordinates_long: coordinates_long,
        fallback_title: fallback_title,
        data_url: external_url
      })
    elsif :fallback == file_type.to_sym
      data.merge!({
        fallback_title: fallback_title,
        data_url: external_url
      })
   end
   data
  end

  private

  def set_file_extension
    if self.external_url && !self.fallback?
      self.extension = Pathname.new(URI(external_url).path).extname rescue nil
    end
  end

end
