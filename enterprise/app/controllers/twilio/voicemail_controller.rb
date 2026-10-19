# Twilio's next step once a caller has left a voicemail: the recording itself arrives on the
# recording status callback, so the call just ends.
class Twilio::VoicemailController < ApplicationController
  def create
    render xml: Twilio::TwiML::VoiceResponse.new(&:hangup).to_s
  end
end
