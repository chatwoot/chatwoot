class Twilio::DeliveryStatusController < ApplicationController
  include TwilioMessagingSignatureVerification

  def create
    Webhooks::TwilioDeliveryStatusJob.perform_later(permitted_params.to_unsafe_hash)

    head :no_content
  end

  private

  def twilio_channel
    Twilio::DeliveryStatusService.find_channel(permitted_params)
  end

  def twilio_webhook_url
    Rails.application.routes.url_helpers.twilio_delivery_status_index_url
  end

  def permitted_params
    params.permit(
      :AccountSid,
      :From,
      :MessageSid,
      :MessagingServiceSid,
      :MessageStatus,
      :ErrorCode,
      :ErrorMessage
    )
  end
end
