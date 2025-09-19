class Twilio::VoiceController < ApplicationController
  before_action :set_inbox!

  def status
    Voice::StatusUpdateService.new(
      account: @inbox.account,
      call_sid: params[:CallSid],
      call_status: params[:CallStatus]
    ).perform
    head :no_content
  end

  def call_twiml
    account = @inbox.account
    call_sid = params[:CallSid]
    from_number = params[:From].to_s
    to_number = params[:To].to_s

    builder = Voice::InboundCallBuilder.new(
      account: account,
      inbox: @inbox,
      from_number: from_number,
      to_number: to_number,
      call_sid: call_sid
    ).perform
    render xml: builder.twiml_response
  end

  private

  def set_inbox!
    # Resolve from the digits in the route param and look up exact E.164 match
    digits = params[:phone].to_s.gsub(/\D/, '')
    e164 = "+#{digits}"
    channel = Channel::Voice.find_by!(phone_number: e164)
    @inbox = channel.inbox
  end
end
