class Webhooks::TelnyxSmsEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    event_type = params.dig('data', 'event_type')
    payload = params.dig('data', 'payload') || {}

    case event_type
    when 'message.received'
      handle_incoming(payload)
    when 'message.finalized'
      handle_delivery_status(payload)
    end
  end

  private

  def handle_incoming(payload)
    to_number = payload.dig('to', 0, 'phone_number') || payload['to']
    channel = Channel::TelnyxSms.find_by(phone_number: to_number)
    return unless channel

    Sms::IncomingMessageService.new(
      inbox: channel.inbox,
      params: get_incoming_params(payload)
    ).perform
  end

  def handle_delivery_status(payload)
    from_number = payload.dig('from', 'phone_number')
    channel = Channel::TelnyxSms.find_by(phone_number: from_number)
    return unless channel

    Sms::TelnyxDeliveryStatusService.new(
      inbox: channel.inbox,
      params: payload.with_indifferent_access
    ).perform
  end

  def get_incoming_params(payload)
    {
      id: payload['id'],
      from: payload.dig('from', 'phone_number'),
      to: payload.dig('to', 0, 'phone_number'),
      text: payload['text'],
      media: Array(payload['media']).pluck('url')
    }.with_indifferent_access
  end
end
