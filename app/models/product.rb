# == Schema Information
#
# Table name: products
#
#  id                :bigint           not null, primary key
#  custom_attributes :jsonb
#  disabled          :boolean          default(FALSE), not null
#  name              :string           not null
#  price             :float
#  short_name        :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#
# Indexes
#
#  index_product_on_account_id_and_short_name  (account_id,short_name) UNIQUE
#  index_products_on_account_id                (account_id)
#
class Product < ApplicationRecord
  belongs_to :account
  before_validation :prepare_jsonb_attributes

  def prepare_jsonb_attributes
    self.custom_attributes = {} if custom_attributes.blank?
  end

  def webhook_data
    {
      id: id,
      name: name,
      short_name: short_name,
      price: price,
      custom_attributes: custom_attributes
    }
  end
end
