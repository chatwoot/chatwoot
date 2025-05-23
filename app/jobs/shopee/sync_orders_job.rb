class Shopee::SyncOrdersJob < ApplicationJob
  UPDATE_FROM = 1.hour

  queue_as :medium

  def perform(channel_id:)
    @channel = Channel::Shopee.find(channel_id)

    shopee_order_numbers = fetch_updated_orders
    shopee_order_numbers.each do |order_number|
      Shopee::SyncOrderInfoService.new(channel_id: channel.id, order_number: order_number).perform
    end
  end

  private

  attr_reader :channel

  def access_params
    {
      shop_id: channel.shop_id,
      access_token: channel.access_token
    }
  end

  def fetch_updated_orders
    filter_params = {
      time_range_field: :update_time,
      time_from: UPDATE_FROM.ago.to_i
    }
    Integrations::Shopee::Order.new(access_params)
                               .all(filter_params)
                               .pluck('order_sn')
  end
end
