class Twilio::VoiceController < ApplicationController
  require 'digest'
  before_action :set_inbox!
  before_action :validate_twilio_signature!, only: %i[status conference_status]

  def status
    call_sid = params[:CallSid]
    call_status = params[:CallStatus]
    Rails.logger.info(
      "TWILIO_VOICE_STATUS account=#{@inbox.account_id} phone_param=#{params[:phone]} call_sid=#{call_sid} status=#{call_status}"
    )
    Voice::StatusUpdateService.new(
      account: @inbox.account,
      call_sid: call_sid,
      call_status: call_status
    ).perform
    head :no_content
  rescue StandardError => e
    Rails.logger.error(
      "TWILIO_VOICE_STATUS_ERROR account=#{@inbox.account_id} call_sid=#{call_sid} error=#{e.class}: #{e.message}"
    )
    Sentry.capture_exception(e) if defined?(Sentry)
    Raven.capture_exception(e) if defined?(Raven)
    head :no_content
  end

  def call_twiml
    account = @inbox.account
    call_sid = params[:CallSid]
    from_number = params[:From].to_s
    to_number = params[:To].to_s
    log_from = Digest::SHA1.hexdigest(from_number)[0, 8]
    log_to = to_number.start_with?('conf_account_') ? to_number : Digest::SHA1.hexdigest(to_number)[0, 8]
    Rails.logger.info(
      "TWILIO_VOICE_TWIML_REQUEST account=#{account.id} phone_param=#{params[:phone]} call_sid=#{call_sid} from_hash=#{log_from} to=#{log_to}"
    )

    # Ensure conversation exists to compute readable conference SID (display_id)
    agent_leg = params[:is_agent].to_s == 'true' || from_number.start_with?('client:') || to_number.start_with?('conf_account_')
    conversation = nil
    if agent_leg
      # Prefer explicit conversation_id param if present (from WebRTC Client)
      if params[:conversation_id].present?
        conversation = account.conversations.find_by(display_id: params[:conversation_id])
      elsif to_number =~ /^conf_account_\d+_conv_(\d+)$/
        display_id = Regexp.last_match(1)
        conversation = account.conversations.find_by(display_id: display_id)
      end
    else
      conversation = account.conversations.find_by(identifier: call_sid)

      if conversation
        ensure_conference_sid!(conversation)
        call_direction = conversation.additional_attributes&.dig('call_direction') || 'outbound'
        conference_sid = conversation.additional_attributes['conference_sid']
        Voice::CallMessageBuilder.new(
          conversation: conversation,
          direction: call_direction,
          call_sid: call_sid,
          conference_sid: conference_sid,
          from_number: outbound_from_number(conversation, from_number),
          to_number: outbound_to_number(conversation, to_number),
          user: nil
        ).perform
      else
        conversation = Voice::CallOrchestratorService.new(
          account: account,
          inbox: @inbox,
          direction: :inbound,
          phone_number: from_number,
          call_sid: call_sid
        ).inbound!
      end
    end

    unless conversation
      Rails.logger.error("TWILIO_VOICE_TWIML_ERROR conversation_not_found call_sid=#{call_sid}")
      fallback = Twilio::TwiML::VoiceResponse.new
      fallback.say(message: 'We are unable to connect your call at this time. Please try again later.')
      fallback.hangup
      return render xml: fallback.to_s
    end

    conference_sid = "conf_account_#{account.id}_conv_#{conversation.display_id}"
    Rails.logger.info("TWILIO_VOICE_TWIML_CONFERENCE account=#{account.id} conference_sid=#{conference_sid}")

    response = Twilio::TwiML::VoiceResponse.new
    host = ENV.fetch('FRONTEND_URL', '')
    phone_digits = @inbox.channel.phone_number.delete_prefix('+')
    conf_status_url = "#{host}/twilio/voice/conference_status/#{phone_digits}"
    # NOTE: agent_leg computed above
    response.say(message: 'Please wait while we connect you to an agent') unless agent_leg
    response.dial do |dial|
      dial.conference(
        conference_sid,
        start_conference_on_enter: agent_leg,
        end_conference_on_exit: false,
        beep: 'on',
        status_callback: conf_status_url,
        status_callback_event: 'start end join leave',
        status_callback_method: 'POST'
      )
    end
    render xml: response.to_s
  end

  # Twilio Conference Status webhook
  # Receives events: conference-start, conference-end, participant-join, participant-leave
  def conference_status
    account = @inbox.account
    event = params[:StatusCallbackEvent].to_s
    conference_sid = params[:ConferenceSid].to_s
    call_sid = params[:CallSid].to_s

    Rails.logger.info(
      "TWILIO_VOICE_CONFERENCE_STATUS account=#{account.id} event=#{event} conference_sid=#{conference_sid} call_sid=#{call_sid}"
    )

    # Map Twilio events to internal events
    mapped = case event
             when /conference-start/i then 'start'
             when /conference-end/i then 'end'
             when /participant-join/i then 'join'
             when /participant-leave/i then 'leave'
             end

    if mapped
      conversation = account.conversations
                            .where("additional_attributes->>'conference_sid' = ?", conference_sid)
                            .first
      if conversation
        Voice::ConferenceManagerService.new(
          conversation: conversation,
          event: mapped,
          call_sid: call_sid,
          participant_label: nil
        ).process
      else
        Rails.logger.warn(
          "TWILIO_VOICE_CONFERENCE_STATUS_CONV_NOT_FOUND account=#{account.id} conf=#{conference_sid}"
        )
      end
    else
      Rails.logger.warn(
        "TWILIO_VOICE_CONFERENCE_STATUS_EVENT_UNHANDLED account=#{account.id} event=#{event}"
      )
    end

    head :no_content
  end

  private

  def ensure_conference_sid!(conversation)
    attrs = conversation.additional_attributes || {}
    return if attrs['conference_sid'].present?

    attrs['conference_sid'] = "conf_account_#{conversation.account_id}_conv_#{conversation.display_id}"
    conversation.update!(additional_attributes: attrs)
  end

  def outbound_from_number(conversation, fallback)
    conversation.inbox&.channel&.phone_number || fallback
  end

  def outbound_to_number(conversation, fallback)
    conversation.contact&.phone_number || fallback
  end

  def set_inbox!
    # Resolve from the digits in the route param and look up exact E.164 match
    digits = params[:phone].to_s.gsub(/\D/, '')
    e164 = "+#{digits}"
    channel = Channel::Voice.find_by!(phone_number: e164)
    @inbox = channel.inbox
  end

  def validate_twilio_signature!
    cfg = @inbox.channel.provider_config_hash
    token = cfg['auth_token']
    validator = ::Twilio::Security::RequestValidator.new(token)
    signature = request.headers['X-Twilio-Signature']
    url = request.url
    params = request.request_parameters.presence || request.query_parameters
    valid = validator.validate(url, params, signature)
    unless valid
      Rails.logger.warn("TWILIO_SIGNATURE_INVALID path=#{request.path}")
      head :forbidden
    end
  rescue StandardError => e
    Rails.logger.error("TWILIO_SIGNATURE_ERROR #{e.class}: #{e.message}")
    head :forbidden
  end
end
