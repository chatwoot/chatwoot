class Webhooks::TwilioEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    # Skip processing if Body parameter is not present
    return if params[:Body].blank? && params[:MediaUrl0].blank?

    # Process the Twilio webhook event in the background
    ::Twilio::IncomingMessageService.new(params: params).perform
  end
end
