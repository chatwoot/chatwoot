# == Schema Information
#
# Table name: canned_attachments
#
#  id                 :integer          not null, primary key
#  file_type          :integer          default("image")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :integer          not null
#  canned_response_id :integer          not null
#
# Indexes
#
#  index_canned_attachments_on_account_id          (account_id)
#  index_canned_attachments_on_canned_response_id  (canned_response_id)
#

class CannedAttachment < ApplicationRecord
  include Attachmentable

  belongs_to :account
  belongs_to :canned_response

  def push_event_data
    return unless file_type

    base_data.merge(file_metadata)
  end

  private

  def file_metadata
    {
      data_url: file_url,
      thumb_url: thumb_url,
      file_size: file.byte_size,
      width: file.metadata[:width],
      height: file.metadata[:height]
    }
  end

  def base_data
    {
      id: id,
      canned_response_id: canned_response_id,
      file_type: file_type,
      account_id: account_id
    }
  end

  def should_validate_file?
    file.attached?
  end
end
