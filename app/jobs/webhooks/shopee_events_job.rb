class Webhooks::ShopeeEventsJob < ApplicationJob
  queue_as :default

  REQUIRED_KEYS = %i[msg_id data shopee].freeze

  # https://open.shopee.com/developer-guide/18
  WEBCHAT = 10
  ORDER_EVENTS = [3, 4, 15, 23, 24, 25]
  ITEM_EVENTS = [8, 11, 13, 16, 22]

  def perform(params: {})
    @params = params
    return unless valid_event_payload?

    case params[:code]
    when WEBCHAT
      Shopee::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
    when *ORDER_EVENTS
      order_number = params.dig(:data, :ordersn) || params.dig(:data, :order_sn)
      Shopee::SyncOrderInfoService.new(channel_id: channel.id, order_number: order_number).perform
    when *ITEM_EVENTS
      Shopee::SyncProductInfoJob.perform_later(channel_id: channel.id, shopee_item_ids: [params.dig(:data, :item_id).presence].compact)
    end
  end

  private

  attr_reader :params, :channel

  def valid_event_payload?
    return false if params.dig(:shopee, :shop_id).blank?

    @channel = Channel::Shopee.find_by(shop_id: params.dig(:shopee, :shop_id))
    return false unless @channel

    params.slice(*REQUIRED_KEYS).keys.length == REQUIRED_KEYS.length
  end
end
