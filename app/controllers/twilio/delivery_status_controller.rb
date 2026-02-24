class Twilio::DeliveryStatusController < ApplicationController
  include TwilioSignatureVerifyConcern

  def create
    Webhooks::TwilioDeliveryStatusJob.perform_later(permitted_params.to_unsafe_hash)

    head :no_content
  end

  private

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

  def channel_lookup_phone_numbers
    [params[:From]].compact_blank
  end
end
