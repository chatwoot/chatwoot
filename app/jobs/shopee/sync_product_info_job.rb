class Shopee::SyncProductInfoJob < ApplicationJob
  queue_as :medium

  def perform(channel_id:, shopee_item_ids:)
    return if shopee_item_ids.blank?

    @channel = Channel::Shopee.find(channel_id)
    @shopee_item_ids = shopee_item_ids
    @items = fetch_products
    sync_products
  end

  private

  attr_reader :channel, :shopee_item_ids

  def fetch_products
    Integrations::Shopee::Product.new(
      shop_id: channel.shop_id,
      access_token: channel.access_token
    ).detail(ids: shopee_item_ids)
  end

  def sync_products
    @items.each do |item|
      shopee_item = Shopee::Item.find_or_initialize_by(
        shop_id: channel.shop_id,
        code: item['item_id']
      )
      shopee_item.update!(
        name: item['item_name'],
        sku: item['item_sku'],
        status: item['item_status'],
        meta: metadata(item)
      )
      shopee_item.resync_stock!
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Failed to process product: #{item['item_id']}, Error: #{e.message}")
    end
  end

  def metadata(item)
    {
      price_info: item['price_info'],
      pre_order: item['pre_order'],
      image_urls: item.dig('image', 'image_url_list'),
      brand_name: item.dig('brand', 'original_brand_name')
    }
  end
end
