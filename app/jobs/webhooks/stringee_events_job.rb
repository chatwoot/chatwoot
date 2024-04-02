class Webhooks::StringeeEventsJob < ApplicationJob
  queue_as :default

  SUPPORTED_STATUSES = %w[ended].freeze

  def perform(params = {})
    return unless SUPPORTED_STATUSES.include?(params[:call_status])

    number = is_incomming(params) ? params[:to][:number] : params[:from][:number]
    channel = Channel::StringeePhoneCall.find_by(phone_number: number)
    return unless channel

    Stringee::CallEventsService.new(inbox: channel.inbox, params: params.with_indifferent_access).perform
  end

  private

  def is_incomming(params)
    params[:callCreatedReason] == 'EXTERNAL_CALL_IN'
  end
end
