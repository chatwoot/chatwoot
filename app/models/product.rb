# == Schema Information
#
# Table name: products
#
#  id             :bigint           not null, primary key
#  currency       :string           default("SAR"), not null
#  description_ar :text
#  description_en :text
#  price          :decimal(10, 2)   not null
#  title_ar       :string
#  title_en       :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#
# Indexes
#
#  index_products_on_account_id               (account_id)
#  index_products_on_account_id_and_title_en  (account_id,title_en) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Product < ApplicationRecord
  belongs_to :account

  has_one_attached :image

  validates :title_en, presence: true, uniqueness: { scope: :account_id }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true

  default_scope { order(created_at: :desc) }

  def image_url
    return unless image.attached?

    Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
  end
end
