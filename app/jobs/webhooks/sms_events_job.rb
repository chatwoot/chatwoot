class Webhooks::SmsEventsJob < ApplicationJob
  queue_as :default

  SUPPORTED_EVENTS = %w[message-received message-delivered message-failed].freeze

  def perform(params = {})
    return unless SUPPORTED_EVENTS.include?(params[:event])

    channel = Channel::Sms.find_by(phone_number: params[:to])
    return unless channel

    Sms::DeliveryStatusService.new(channel: channel, params: params[:message].with_indifferent_access).perform if delivery_event?

    Sms::IncomingMessageService.new(inbox: channel.inbox, params: params[:message].with_indifferent_access).perform
  end

  private

  def delivery_event?
    params[:event] == 'message-delivered' || params[:event] == 'message-failed'
  end
end
