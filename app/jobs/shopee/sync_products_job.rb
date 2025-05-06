class Shopee::SyncProductsJob < ApplicationJob
  UPDATE_FROM = 1.day

  queue_as :medium

  def perform(channel_id:)
    @channel = Channel::Shopee.find(channel_id)

    shopee_item_ids = fetch_updated_products
    Shopee::SyncProductInfoJob.perform_later(channel_id: channel.id, shopee_item_ids: shopee_item_ids)
  end

  private

  attr_reader :channel

  def access_params
    {
      shop_id: channel.shop_id,
      access_token: channel.access_token,
    }
  end

  def fetch_updated_products
    Integrations::Shopee::Product.new(access_params)
      .all(update_time_from: UPDATE_FROM.ago.to_i)
      .pluck('item_id')
  end

end
