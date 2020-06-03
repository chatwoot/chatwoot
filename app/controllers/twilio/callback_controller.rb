class Twilio::CallbackController < ApplicationController
  def create
    ::Twilio::IncomingMessageService.new(params: permitted_params).perform

    head :no_content
  end

  private

  def permitted_params
    params.permit(
      :ApiVersion,
      :SmsSid,
      :From,
      :ToState,
      :ToZip,
      :AccountSid,
      :MessageSid,
      :FromCountry,
      :ToCity,
      :FromCity,
      :To,
      :FromZip,
      :Body,
      :ToCountry,
      :FromState,
      :MediaUrl0,
      :MediaContentType0
    )
  end
end
