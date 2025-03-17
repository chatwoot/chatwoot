class Webhooks::TwilioEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    # Skip processing if Body parameter or MediaUrl0 is not present
    # This is to skip processing delivery events being delivered to this endpoint
    return if params[:Body].blank? && params[:MediaUrl0].blank?

    ::Twilio::IncomingMessageService.new(params: params).perform
  end
end
