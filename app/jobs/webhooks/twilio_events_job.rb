class Webhooks::TwilioEventsJob < ApplicationJob
  queue_as :low

  def perform(params = {})
    # Skip processing if Body parameter, MediaUrl0, or location data is not present
    # This is to skip processing delivery events being delivered to this endpoint
    return if params[:Body].blank? && params[:MediaUrl0].blank? && !valid_location_message?(params)

    ::Twilio::IncomingMessageService.new(params: params).perform
  end

  private

  def valid_location_message?(params)
    params[:MessageType] == 'location' && params[:Latitude].present? && params[:Longitude].present?
  end
end
