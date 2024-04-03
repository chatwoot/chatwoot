class Webhooks::StringeeEventsJob < ApplicationJob
  queue_as :default

  SUPPORTED_STATUSES = %w[ended].freeze

  def perform(params = {})
    return unless SUPPORTED_STATUSES.include?(params[:call_status])
    return unless ENV.fetch('STRINGEE_ACCOUNT_SID', nil) == params[:account_sid]

    channel = nil
    if params[:queueId].present?
      channel = Channel::StringeePhoneCall.find_by(queue_id: params[:queueId])
    else
      number = incoming?(params) ? params[:to][:number] : params[:from][:number]
      number.prepend('+') unless number.start_with?('+')
      channel = Channel::StringeePhoneCall.find_by(phone_number: number)
    end
    return unless channel

    Stringee::CallEventsService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
  end

  private

  def incoming?(params)
    params[:callCreatedReason] == 'EXTERNAL_CALL_IN'
  end
end
