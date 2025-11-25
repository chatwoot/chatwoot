# == Schema Information
#
# Table name: product_media
#
#  id                 :bigint           not null, primary key
#  display_order      :integer          default(0)
#  file_name          :string           not null
#  file_size          :integer
#  file_type          :string           not null
#  file_url           :string           not null
#  is_primary         :boolean          default(FALSE)
#  mime_type          :string
#  thumbnail_url      :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  last_updated_by_id :bigint
#  product_catalog_id :bigint           not null
#  user_id            :bigint
#
# Indexes
#
#  index_product_media_on_file_type                             (file_type)
#  index_product_media_on_is_primary                            (is_primary)
#  index_product_media_on_last_updated_by_id                    (last_updated_by_id)
#  index_product_media_on_product_catalog_id                    (product_catalog_id)
#  index_product_media_on_product_catalog_id_and_display_order  (product_catalog_id,display_order)
#  index_product_media_on_user_id                               (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (last_updated_by_id => users.id)
#  fk_rails_...  (product_catalog_id => product_catalogs.id)
#  fk_rails_...  (user_id => users.id)
#
class ProductMedium < ApplicationRecord
  belongs_to :product_catalog
  belongs_to :user, optional: true
  belongs_to :last_updated_by, class_name: 'User', optional: true

  validates :product_catalog_id, presence: true
  validates :file_type, presence: true
  validates :file_name, presence: true
  validates :file_url, presence: true
  validates :file_size, numericality: { greater_than: 0 }, allow_nil: true
  validates :display_order, numericality: { greater_than_or_equal_to: 0 }

  validate :validate_file_extension

  enum file_type: {
    image: 'IMAGE',
    video: 'VIDEO',
    audio: 'AUDIO',
    document: 'DOCUMENT',
    other: 'OTHER'
  }

  scope :primary, -> { where(is_primary: true) }
  scope :ordered, -> { order(:display_order) }
  scope :images, -> { where(file_type: 'IMAGE') }
  scope :videos, -> { where(file_type: 'VIDEO') }

  before_validation :set_file_type_from_extension, if: -> { file_type.blank? && file_name.present? }
  before_save :ensure_only_one_primary_per_type, if: -> { is_primary_changed? && is_primary? }

  private

  def validate_file_extension
    return if file_name.blank?
    return if file_type.blank?

    extension = File.extname(file_name).downcase

    # Map enum keys to valid extensions
    valid_extensions_by_type = {
      'image' => %w[.jpg .jpeg .png .gif .webp .svg],
      'video' => %w[.mp4 .avi .mov .wmv .flv .webm],
      'audio' => %w[.mp3 .wav .ogg .m4a],
      'document' => %w[.pdf .doc .docx .xls .xlsx .txt],
      'other' => []
    }

    return if file_type == 'other'

    valid_extensions = valid_extensions_by_type[file_type]
    return if valid_extensions&.include?(extension)

    errors.add(:file_name, "has an invalid extension for type #{file_type}")
  end

  def set_file_type_from_extension
    extension = File.extname(file_name).downcase

    self.file_type = case extension
                     when '.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'
                       'IMAGE'
                     when '.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm'
                       'VIDEO'
                     when '.mp3', '.wav', '.ogg', '.m4a'
                       'AUDIO'
                     when '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.txt'
                       'DOCUMENT'
                     else
                       'OTHER'
                     end
  end

  def ensure_only_one_primary_per_type
    # Remove primary flag from other media of the same type for this product
    ProductMedium.where(
      product_catalog_id: product_catalog_id,
      file_type: file_type,
      is_primary: true
    ).where.not(id: id).update_all(is_primary: false)
  end
end

ProductMedium.include_mod_with('Audit::ProductMedium')
