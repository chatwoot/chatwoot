class Twilio::DeliveryStatusController < ApplicationController
  def create
    ::Twilio::DeliveryStatusService.new(params: permitted_params).perform

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
end
