class WhatsappInteractivePresetMedia < ApplicationRecord
  include FileTypeHelper

  belongs_to :whatsapp_interactive_preset, inverse_of: :media
  has_one_attached :file

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 },
                       uniqueness: { scope: :whatsapp_interactive_preset_id }
  validates :file, presence: true

  delegate :account_id, to: :whatsapp_interactive_preset

  def media_type
    file_type(file.blob.content_type)
  end
end
