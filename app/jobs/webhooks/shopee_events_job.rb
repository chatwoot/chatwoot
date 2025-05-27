class Webhooks::ShopeeEventsJob < ApplicationJob
  queue_as :default

  REQUIRED_KEYS = %i[msg_id data shopee].freeze

  def perform(params: {})
    @params = params
    return unless valid_event_payload?

    Shopee::IncomingMessageService.new(inbox: channel.inbox, params: params).perform
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
