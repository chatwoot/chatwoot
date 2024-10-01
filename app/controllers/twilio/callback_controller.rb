class Twilio::CallbackController < ApplicationController
  def create
    ::Twilio::IncomingMessageService.new(params: permitted_params).perform

    head :no_content
  end

  private

  def permitted_params # rubocop:disable Metrics/MethodLength
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
      :MessageType,#location,attachment
      :MessageDirection,#location,attachment
      :Longitude,
      :Latitude,
      :LocationLabel,
      :CityLabel,
      :isPrivate,
      :FullName,
      :Subject,
      :SubSubject,
      :To,
      :FromZip,
      :Body,
      :ToCountry,
      :FromState,
      :MediaUrl0,
      :MediaContentType0,
      :MessagingServiceSid
    )
  end
end
