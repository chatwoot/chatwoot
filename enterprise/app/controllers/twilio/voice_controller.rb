class Twilio::VoiceController < ApplicationController
  before_action :set_inbox!

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
    Rails.logger.info(
      "TWILIO_VOICE_TWIML_REQUEST account=#{account.id} phone_param=#{params[:phone]} call_sid=#{call_sid} from=#{from_number} to=#{to_number}"
    )

    agent_leg = from_number.start_with?('client:')
    direction = (params['Direction'] || params['CallDirection']).to_s

    conversation = nil

    if agent_leg
      conversation = account.conversations.find_by(display_id: params[:conversation_id]) if params[:conversation_id].present?
    else
      conversation = case direction
                     when 'inbound' then handle_inbound_leg(account, call_sid, from_number, to_number)
                     when 'outbound-api', 'outbound-dial'
                       handle_outbound_leg(account, direction, call_sid, from_number, to_number)
                     else
                       handle_fallback_leg(account, call_sid, from_number)
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
    participant_label = agent_leg ? "agent" : "contact"

    response.dial do |dial|
      dial.conference(
        conference_sid,
        start_conference_on_enter: agent_leg,
        end_conference_on_exit: false,
        beep: 'on',
        status_callback: conf_status_url,
        status_callback_event: 'start end join leave',
        status_callback_method: 'POST',
        participant_label: participant_label
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
    friendly_name = params[:FriendlyName].to_s
    call_sid = params[:CallSid].to_s
    participant_label = params[:ParticipantLabel].to_s

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
      conversation = nil
      if friendly_name.present?
        conversation = account.conversations
                              .where("additional_attributes->>'conference_sid' = ?", friendly_name)
                              .first
      end

      if conversation.nil? && conference_sid.present?
        conversation = account.conversations
                              .where("additional_attributes->>'twilio_conference_sid' = ?", conference_sid)
                              .first
      end

      conversation ||= account.conversations.find_by(identifier: call_sid) if call_sid.present?

      if conversation
        if conference_sid.present?
          attrs = conversation.additional_attributes || {}
          if attrs['twilio_conference_sid'] != conference_sid
            attrs['twilio_conference_sid'] = conference_sid
            conversation.update!(additional_attributes: attrs)
          end
        end

        Voice::ConferenceManagerService.new(
          conversation: conversation,
          event: mapped,
          call_sid: call_sid,
          participant_label: participant_label
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

  def handle_inbound_leg(account, call_sid, from_number, to_number)
    conversation = account.conversations.find_by(identifier: call_sid)
    return Voice::CallSessionSyncService.new(
      conversation: conversation,
      call_sid: call_sid,
      message_call_sid: call_sid,
      from_number: from_number,
      to_number: to_number,
      direction: 'inbound'
    ).perform if conversation

    Voice::CallOrchestratorService.new(
      account: account,
      inbox: @inbox,
      direction: :inbound,
      phone_number: from_number,
      call_sid: call_sid
    ).inbound!
  end

  def handle_outbound_leg(account, direction, call_sid, from_number, to_number)
    parent_sid = params['ParentCallSid'].presence
    lookup_sid = direction == 'outbound-dial' ? parent_sid || call_sid : call_sid
    conversation = account.conversations.find_by(identifier: lookup_sid)
    return unless conversation

    Voice::CallSessionSyncService.new(
      conversation: conversation,
      call_sid: call_sid,
      message_call_sid: conversation.identifier,
      from_number: from_number,
      to_number: to_number,
      direction: 'outbound'
    ).perform
  end

  def handle_fallback_leg(account, call_sid, from_number)
    Rails.logger.warn(
      "TWILIO_VOICE_TWIML_UNKNOWN_DIRECTION account=#{account.id} call_sid=#{call_sid} direction=#{params['Direction'] || params['CallDirection']}"
    )
    existing = account.conversations.find_by(identifier: call_sid)
    return Voice::CallSessionSyncService.new(
      conversation: existing,
      call_sid: call_sid,
      message_call_sid: call_sid,
      from_number: from_number,
      to_number: params[:To],
      direction: 'inbound'
    ).perform if existing

    Voice::CallOrchestratorService.new(
      account: account,
      inbox: @inbox,
      direction: :inbound,
      phone_number: from_number,
      call_sid: call_sid
    ).inbound!
  rescue StandardError => e
    Rails.logger.error(
      "TWILIO_VOICE_TWIML_FALLBACK_ERROR account=#{account.id} call_sid=#{call_sid} error=#{e.class}: #{e.message}"
    )
    nil
  end

  def set_inbox!
    # Resolve from the digits in the route param and look up exact E.164 match
    digits = params[:phone].to_s.gsub(/\D/, '')
    e164 = "+#{digits}"
    channel = Channel::Voice.find_by!(phone_number: e164)
    @inbox = channel.inbox
  end
end
