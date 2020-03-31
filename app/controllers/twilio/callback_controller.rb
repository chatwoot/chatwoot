class Twilio::CallbackController < Twitter::BaseController
  def create
    twiml = Twilio::TwiML::MessagingResponse.new do |r|
      r.message body: 'The Robots are coming! Head for the hills!'
    end

    content_type 'text/xml'
    render twiml.to_s
  end
end
