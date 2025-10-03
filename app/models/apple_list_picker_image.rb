# == Schema Information
#
# Table name: apple_list_picker_images
#
#  id            :bigint           not null, primary key
#  description   :string
#  identifier    :string           not null
#  original_name :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  inbox_id      :bigint           not null
#
# Indexes
#
#  index_apple_list_picker_images_on_account_id               (account_id)
#  index_apple_list_picker_images_on_inbox_id                 (inbox_id)
#  index_apple_list_picker_images_on_inbox_id_and_identifier  (inbox_id,identifier) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (inbox_id => inboxes.id)
#
class AppleListPickerImage < ApplicationRecord
  belongs_to :account
  belongs_to :inbox

  has_one_attached :image

  validates :identifier, presence: true, uniqueness: { scope: :inbox_id }
  validates :image, presence: true

  # Get all images for an inbox, ordered by most recent
  scope :for_inbox, ->(inbox_id) { where(inbox_id: inbox_id).order(created_at: :desc) }

  # Find by identifier within an inbox
  def self.find_by_identifier(inbox_id, identifier)
    find_by(inbox_id: inbox_id, identifier: identifier)
  end

  # Get image data as base64 for Apple Messages API
  def image_data_base64
    return nil unless image.attached?

    image.download.then { |data| Base64.strict_encode64(data) }
  end

  # Get image URL for preview
  def image_url
    return nil unless image.attached?

    Rails.application.routes.url_helpers.rails_blob_url(image, only_path: true)
  end
end
