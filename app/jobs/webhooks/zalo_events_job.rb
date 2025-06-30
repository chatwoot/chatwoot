class Webhooks::ZaloEventsJob < ApplicationJob
  queue_as :default

  REQUIRED_KEYS = %i[app_id sender recipient event_name message timestamp].freeze

  def perform(params: {})
    @params = params
    return unless valid_event_payload?

    case params[:event_name]
    when *Zalo::CreateMessageService::ALL_EVENTS
      Zalo::CreateMessageService.new(channel, params).process
    else
      Rails.logger.warn("Unhandled Zalo event type: #{params[:event_name]}")
    end
  end

  private

  attr_reader :params, :channel

  def valid_event_payload?
    return false if params.dig(:recipient, :id).blank?
    return false unless channel

    params.slice(*REQUIRED_KEYS).keys.length == REQUIRED_KEYS.length
  end

  def channel
    @channel ||= Channel::Zalo.find_by(oa_id: params.dig(:sender, :id))
    @channel ||= Channel::Zalo.find_by(oa_id: params.dig(:recipient, :id))
  end
end
