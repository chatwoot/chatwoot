class Twilio::VoiceController < ActionController::Base
  skip_forgery_protection

  before_action :set_call_details, only: %i[status_callback simple_twiml]
  before_action :set_inbox,        only: %i[status_callback simple_twiml]

 
  def status_callback
    return head :ok unless @inbox

    conversation = Voice::ConversationFinderService.new(
      account:      @inbox.account,
      call_sid:     @call_sid,
      phone_number: incoming_number,
      is_outbound:  outbound?,
      inbox:        @inbox
    ).perform

    Voice::CallStatus::Manager.new(
      conversation: conversation,
      call_sid:     @call_sid,
      provider:     :twilio
    ).process_status_update(params[:CallStatus], params[:CallDuration]&.to_i, first_status_response?)

    head :ok
  end

  def simple_twiml
    return fallback_twiml unless @inbox

    conversation = Voice::ConversationFinderService.new(
      account:      @inbox.account,
      call_sid:     @call_sid,
      phone_number: incoming_number,
      is_outbound:  outbound?,
      inbox:        @inbox
    ).perform

    Voice::CallStatus::Manager.new(
      conversation: conversation,
      call_sid:     @call_sid,
      provider:     :twilio
    ).process_status_update('in-progress', nil, true)

    conference_name = ensure_conference_name(conversation, params[:conference_name])

    conversation.update!(
      additional_attributes: conversation.additional_attributes.merge(
        'conference_sid'       => conference_name,
        'call_direction'       => outbound? ? 'outbound' : 'inbound',
        'requires_agent_join'  => true
      )
    )

    render_twiml do |r|
      r.say(message: 'Please wait while we connect you to an agent')

      # Enable real-time transcription for this call leg
      # For outbound calls, we're connecting to the contact, so this track is for the contact
      contact_id = conversation.contact_id
      callback_url = "#{base_url}/twilio/transcription_callback?account_id=#{@inbox.account_id}&conference_sid=#{conference_name}&speaker_type=contact&contact_id=#{contact_id}"
      Rails.logger.info("📞 VoiceController: Setting transcription callback to: #{callback_url}")

      r.start do |start|
        start.transcription(
          status_callback_url: callback_url,
          status_callback_method: 'POST',
          track: 'inbound_track',
          language_code: 'en-US'
        )
      end

      # Set up the conference
      conference_callback_url = "#{base_url}/api/v1/accounts/#{@inbox.account_id}/channels/voice/webhooks/conference_status"
      Rails.logger.info("📞 VoiceController: Setting conference callback to: #{conference_callback_url}")

      r.dial do |d|
        d.conference(
          conference_name,
          startConferenceOnEnter: false,
          endConferenceOnExit:    true,
          beep:                   false,
          muted:                  false,
          waitUrl:                '',
          earlyMedia:             true,
          statusCallback:         conference_callback_url,
          statusCallbackMethod:   'POST',
          statusCallbackEvent:    'start end join leave',
          participantLabel:       "caller-#{@call_sid.last(8)}"
        )
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error creating voice conversation: #{e.message}")
    fallback_twiml
  end

  private

  def set_call_details
    @call_sid  = params[:CallSid]
    @direction = params[:Direction]
  end

  def set_inbox
    @inbox = find_inbox(outbound? ? params[:From] : params[:To])
  end

  def outbound?
    @direction == 'outbound-api'
  end

  def incoming_number
    outbound? ? params[:To] : params[:From]
  end

  def first_status_response?
    params[:IsFirstResponseForStatus] == 'true'
  end

  def render_twiml(status: :ok)
    response = Twilio::TwiML::VoiceResponse.new
    yield response
    render xml: response.to_s, status: status
  end

  def build_message(conversation, content)
    Messages::MessageBuilder.new(
      nil,
      conversation,
      content:               content,
      message_type:          :activity,
      additional_attributes: { call_sid: @call_sid, call_status: 'in-progress', user_input: true }
    ).perform
  end

  def input_text
    return "Caller pressed #{params[:Digits]}"           if params[:Digits].present?
    return "Caller said: \"#{params[:SpeechResult]}\""   if params[:SpeechResult].present?

    'Caller responded'
  end

  def ensure_conference_name(conversation, supplied)
    name = supplied.presence ||
           conversation.additional_attributes['conference_sid'] ||
           conversation.additional_attributes['conference_name']

    return name if name&.match?(/^conf_account_\d+_conv_\d+$/)

    "conf_account_#{@inbox.account_id}_conv_#{conversation.display_id}"
  end

  def fallback_twiml
    render_twiml do |r|
      r.say(message: 'Hello from Chatwoot. This is a courtesy call to check on your recent signup.')
      r.pause(length: 1)
      r.say(message: 'We will connect you with an agent shortly.')
      r.hangup
    end
  end

  def base_url
    ENV.fetch('FRONTEND_URL', 'http://localhost:3000')
  end

  def find_inbox(phone_number)
    return nil if phone_number.blank?

    Inbox.joins('INNER JOIN channel_voice ON channel_voice.account_id = inboxes.account_id AND inboxes.channel_id = channel_voice.id')
         .find_by('channel_voice.phone_number = ?', phone_number)
  end

  def find_or_create_conversation(inbox, phone_number, call_sid)
    Voice::ConversationFinderService.new(
      account:      inbox.account,
      call_sid:     call_sid,
      phone_number: phone_number,
      is_outbound:  false,
      inbox:        inbox
    ).perform
  rescue StandardError => e
    Rails.logger.error("find_or_create_conversation error: #{e.message}")
    nil
  end
end