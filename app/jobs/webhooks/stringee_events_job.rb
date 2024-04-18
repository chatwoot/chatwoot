class Webhooks::StringeeEventsJob < ApplicationJob
  queue_as :default

  SUPPORTED_STATUSES = %w[created ended].freeze

  def perform(params = {})
    return unless SUPPORTED_STATUSES.include?(params[:call_status])
    return unless ENV.fetch('STRINGEE_ACCOUNT_SID', nil) == params[:account_sid]

    number = extract_phone_number(params)
    channel = Channel::StringeePhoneCall.find_by(phone_number: number)
    return unless channel

    process_event_params(channel, params)
  end

  private

  def extract_phone_number(params)
    number = incoming?(params) ? params[:to][:alias] : params[:from][:alias]
    number = incoming?(params) ? params[:to][:number] : params[:from][:number] if number.blank?
    number.prepend('+') unless number.start_with?('+')
    number
  end

  def process_event_params(channel, params)
    if delivery_event?(params)
      Stringee::DeliveryStatusService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    else
      Stringee::CallingEventsService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
    end
  end

  def delivery_event?(params)
    params[:call_status] == 'ended'
  end

  def incoming?(params)
    params[:callCreatedReason] == 'EXTERNAL_CALL_IN'
  end
end
