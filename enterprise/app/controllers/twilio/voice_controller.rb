class Twilio::VoiceController < ApplicationController
  before_action :set_inbox

  def status
    return head :no_content unless @inbox

    Voice::StatusUpdateService.new(
      account: @inbox.account,
      call_sid: params[:CallSid],
      call_status: params[:CallStatus],
      call_duration: params[:CallDuration]
    ).perform

    head :no_content
  rescue StandardError => e
    Rails.logger.error("Twilio::VoiceController#status error: #{e.message}")
    head :no_content
  end

  def call_twiml
    return fallback_twiml unless @inbox

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
  rescue StandardError => e
    Rails.logger.error("Twilio::VoiceController#call_twiml error: #{e.message}")
    fallback_twiml
  end

  private

  def render_twiml(status: :ok)
    response = Twilio::TwiML::VoiceResponse.new
    yield response
    render xml: response.to_s, status: status
  end

  def fallback_twiml
    render_twiml(&:hangup)
  end

  def set_inbox
    # Resolve strictly from the digits in the route param and look up exact E.164 match
    digits = params[:phone].to_s.gsub(/\D/, '')
    return if digits.blank?

    e164 = "+#{digits}"
    channel = Channel::Voice.find_by(phone_number: e164)
    @inbox = channel&.inbox
  end
end
