class Webhooks::PlivoEventsJob < ApplicationJob
  queue_as :default

  def perform(params = {})
    params = params.with_indifferent_access
    channel = find_channel(params)
    return unless channel

    if delivery_event?(params)
      Plivo::DeliveryStatusService.new(inbox: channel.inbox, params: delivery_params(params)).perform
    elsif incoming_event?(params)
      Plivo::IncomingMessageService.new(inbox: channel.inbox, params: incoming_params(params)).perform
    end
  end

  private

  def find_channel(params)
    number = params[:To].presence || params[:phone_number]
    return if number.blank?

    number = "+#{number}" unless number.start_with?('+')
    Channel::Plivo.find_by(phone_number: number)
  end

  def delivery_event?(params)
    params[:Status].present?
  end

  def incoming_event?(params)
    params[:Type].blank? || %w[sms mms].include?(params[:Type])
  end

  def incoming_params(params)
    {
      from: params[:From],
      to: params[:To],
      text: params[:Text],
      id: params[:MessageUUID],
      media: media_urls(params)
    }
  end

  def delivery_params(params)
    {
      id: params[:MessageUUID],
      status: params[:Status],
      error_code: params[:ErrorCode]
    }
  end

  def media_urls(params)
    count = params[:MediaCount].to_i
    return [] if count.zero?

    (0...count).map { |index| params["Media#{index}"] }.compact
  end
end
