class Twilio::VoiceController < ApplicationController
  skip_forgery_protection

  before_action :set_call_details, only: %i[status call_twiml]
  before_action :set_inbox,        only: %i[status call_twiml]
  before_action :validate_twilio_signature, only: %i[status call_twiml]

  def status
    begin
      return head :no_content unless @inbox

      conversation = find_conversation_from_params(@inbox.account)
      return head :no_content unless conversation

      if params[:StatusCallbackEvent].present?
        Voice::ConferenceManagerService.new(
          conversation: conversation,
          event: params[:StatusCallbackEvent],
          call_sid: @call_sid,
          participant_label: params[:ParticipantLabel]
        ).process
      elsif params[:CallStatus].present?
        Voice::CallStatus::Manager
          .new(conversation: conversation, call_sid: @call_sid, provider: :twilio)
          .process_status_update(params[:CallStatus], params[:CallDuration])
      end
    rescue StandardError => e
      Rails.logger.error("Twilio::VoiceController#status error: #{e.message}")
    ensure
      head :no_content
    end
  end

  def call_twiml
    return fallback_twiml unless @inbox

    to_param = params[:To].to_s
    agent_leg = to_param.start_with?('conf_account_') || params[:is_agent] == 'true' || params[:identity].to_s.start_with?('agent-')

    conversation = find_conversation_by_conference_to(@inbox.account, to_param) ||
                   Voice::ConversationFinderService.new(
                     account:      @inbox.account,
                     call_sid:     @call_sid,
                     phone_number: incoming_number,
                     is_outbound:  outbound?,
                     inbox:        @inbox
                   ).perform

    conference_sid = ensure_conference_sid(conversation, params[:conference_name])

    updated_attrs = conversation.additional_attributes.merge(
      'conference_sid'      => conference_sid,
      'requires_agent_join' => true
    )
    unless agent_leg
      updated_attrs['call_direction'] ||= outbound? ? 'outbound' : 'inbound'
    end
    conversation.update!(additional_attributes: updated_attrs)

    ensure_call_message(conversation, conference_sid) unless agent_leg

    render_twiml do |r|
      r.say(message: 'Please wait while we connect you to an agent') unless agent_leg

      r.dial do |d|
        d.conference(
          conference_sid,
          startConferenceOnEnter: agent_leg,
          endConferenceOnExit:    true,
          beep:                   false,
          muted:                  false,
          waitUrl:                '',
          earlyMedia:             true,
          statusCallback:         status_callback_url,
          statusCallbackMethod:   'POST',
          statusCallbackEvent:    'start end join leave',
          participantLabel:       "#{agent_leg ? 'agent' : 'caller'}-#{@call_sid.last(8)}"
        )
      end
    end
  rescue StandardError => e
    Rails.logger.error("Twilio::VoiceController#call_twiml error: #{e.message}")
    fallback_twiml
  end

  private

  def set_call_details
    @call_sid  = params[:CallSid]
    @direction = params[:Direction]
  end

  def set_inbox
    # Resolve inbox strictly from the route-scoped phone param (digits only, no '+')
    digits = params[:phone].to_s.gsub(/\D/, '')
    phone  = digits.present? ? "+#{digits}" : nil
    @inbox = find_inbox(phone)
  end

  def outbound?
    @direction == 'outbound-api'
  end

  def incoming_number
    outbound? ? params[:To] : params[:From]
  end

  def render_twiml(status: :ok)
    response = Twilio::TwiML::VoiceResponse.new
    yield response
    render xml: response.to_s, status: status
  end

  def ensure_conference_sid(conversation, supplied)
    sid = supplied.presence || conversation.additional_attributes['conference_sid']
    return sid if sid&.match?(/^conf_account_\d+_conv_\d+$/)

    "conf_account_#{@inbox.account_id}_conv_#{conversation.display_id}"
  end

  def ensure_call_message(conversation, conference_sid)
    existing = conversation.messages.voice_calls.order(created_at: :desc).first
    return if existing.present?

    from_number = outbound? ? @inbox.channel&.phone_number : incoming_number
    to_number   = outbound? ? incoming_number : @inbox.channel&.phone_number

    Voice::CallMessageBuilder.new(
      conversation:   conversation,
      direction:      outbound? ? 'outbound' : 'inbound',
      call_sid:       @call_sid,
      conference_sid: conference_sid,
      from_number:    from_number,
      to_number:      to_number,
      user:           nil
    ).perform
  end

  def fallback_twiml
    render_twiml { |r| r.hangup }
  end

  def find_inbox(phone_number)
    return nil if phone_number.blank?

    normalized = phone_number.to_s
    variants = [normalized, normalized.delete_prefix('+')]

    Inbox.joins('INNER JOIN channel_voice ON channel_voice.account_id = inboxes.account_id AND inboxes.channel_id = channel_voice.id')
         .where('channel_voice.phone_number IN (?)', variants)
         .first
  end

  def find_conversation_by_conference_to(account, to)
    return nil unless to.start_with?('conf_account_')
    match = to.match(/conf_account_(\d+)_conv_(\d+)/)
    return nil unless match && match[2]
    account.conversations.find_by(display_id: match[2])
  end

  # No additional helpers needed; phone-scoped routes handle lookup

  def status_callback_url
    phone_param = @inbox&.channel&.respond_to?(:phone_number) ? @inbox.channel.phone_number.to_s.delete_prefix('+') : nil
    "#{base_url}/twilio/voice/status/#{phone_param}"
  end

  def base_url
    env_url = ENV['FRONTEND_URL']
    (env_url.present? ? env_url : request.base_url).to_s.chomp('/')
  end

  def find_conversation_from_params(account)
    conf_sid = params[:ConferenceSid]
    if conf_sid.present?
      conv = account.conversations.where("additional_attributes->>'conference_sid' = ?", conf_sid).first
      return conv if conv

      if conf_sid.start_with?('conf_account_')
        match = conf_sid.match(/conf_account_(\d+)_conv_(\d+)/)
        if match && match[2]
          return account.conversations.find_by(display_id: match[2])
        end
      end
    end
    nil
  end

  def validate_twilio_signature
    signature = request.headers['X-Twilio-Signature']
    unless signature.present?
      head :unauthorized and return
    end

    # Require inbox resolved from phone-scoped URL
    unless @inbox
      head :unauthorized and return
    end

    cfg = @inbox.channel.provider_config_hash || {}
    auth_token = cfg['auth_token']
    unless auth_token.present?
      head :unauthorized and return
    end

    validator = Twilio::Security::RequestValidator.new(auth_token)
    url = request.original_url
    # Use only the request's native param source for signature validation
    params_hash = request.post? ? request.request_parameters : request.query_parameters
    valid = validator.validate(url, params_hash, signature)
    unless valid
      Rails.logger.error("Invalid Twilio signature for URL: #{url}")
      head :unauthorized and return
    end
  rescue StandardError => e
    Rails.logger.error("Twilio signature validation error: #{e.message}")
    head :unauthorized and return
  end

end
