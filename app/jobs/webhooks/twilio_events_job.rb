class Webhooks::TwilioEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    return if params[:Body].blank? && params[:MediaUrl0].blank?

    ::Twilio::IncomingMessageService.new(params: params).perform
  end
end
