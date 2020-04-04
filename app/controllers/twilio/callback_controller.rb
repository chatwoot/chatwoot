class Twilio::CallbackController < Twitter::BaseController
  def create
    ::Twilio::MessageService.new(params: permitted_params).perform

    twiml = Twilio::TwiML::MessagingResponse.new do |r|
      r.message body: ''
    end

    content_type 'text/xml'
    render twiml.to_s
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
      :FromState
    )
  end
end
