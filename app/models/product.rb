# == Schema Information
#
# Table name: products
#
#  id             :bigint           not null, primary key
#  description_ar :text
#  description_en :text
#  price          :decimal(10, 2)   not null
#  stock          :integer
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
  validates :stock, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  default_scope { order(created_at: :desc) }

  def image_url
    return unless image.attached?

    Rails.application.routes.url_helpers.rails_blob_path(image, only_path: true)
  end

  def in_stock?(quantity = 1)
    stock.nil? || stock >= quantity
  end

  def deduct_stock!(quantity)
    with_lock do
      reload
      raise I18n.t('errors.products.out_of_stock', title: title_en) unless in_stock?(quantity)

      update!(stock: stock - quantity)
    end
  end

  def restore_stock!(quantity)
    return if stock.nil?

    with_lock do
      reload
      update!(stock: stock + quantity)
    end
  end
end
