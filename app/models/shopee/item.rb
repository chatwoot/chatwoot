# == Schema Information
#
# Table name: shopee_items
#
#  id         :bigint           not null, primary key
#  code       :string           not null
#  meta       :jsonb            not null
#  name       :string           not null
#  sku        :string           not null
#  status     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  shop_id    :bigint           not null
#
# Indexes
#
#  index_shopee_items_on_code     (code) UNIQUE
#  index_shopee_items_on_shop_id  (shop_id)
#  index_shopee_items_on_sku      (sku) UNIQUE
#
class Shopee::Item < ApplicationRecord
  validates :shop_id, presence: true
  validates :code, presence: true, uniqueness: true
  validates :sku, presence: true, uniqueness: true
  validates :name, presence: true

  def resync_stock!
    return if channel.nil?

    response = shopee_caller.models(item_id: code)
    self.meta ||= {}
    self.meta['available_stock'] = response['model'].pluck('stock_info_v2').pluck('summary_info').pluck('total_available_stock').sum
    self.save!
  rescue StandardError => e
    Rails.logger.error("Failed to resync stock for item #{code}: #{e.message}")
  end

  def resync_price!
    return if channel.nil?

    response = shopee_caller.detail(ids: [code])
    self.meta ||= {}
    self.meta['price_info'] = response.first['price_info']
    self.save!
  rescue StandardError => e
    Rails.logger.error("Failed to resync price for item #{code}: #{e.message}")
  end

  private

  def channel
    @channel ||= Channel::Shopee.find_by(shop_id: shop_id)
  end

  def shopee_caller
    @shopee_caller ||= Integrations::Shopee::Product.new(
      shop_id: channel.shop_id,
      access_token: channel.access_token,
    )
  end
end
