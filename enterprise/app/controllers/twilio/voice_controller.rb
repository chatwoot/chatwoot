class Twilio::VoiceController < ApplicationController
  CONFERENCE_EVENT_PATTERNS = {
    /conference-start/i => 'start',
    /participant-join/i => 'join',
    /participant-leave/i => 'leave',
    /conference-end/i => 'end'
  }.freeze

  before_action :set_inbox!

  def status
    Voice::StatusUpdateService.new(
      account: current_account,
      call_sid: twilio_call_sid,
      call_status: params[:CallStatus],
      payload: params.to_unsafe_h
    ).perform

    head :no_content
  end

  def call_twiml
    account = current_account
    Rails.logger.info(
      "TWILIO_VOICE_TWIML account=#{account.id} call_sid=#{twilio_call_sid} from=#{twilio_from} direction=#{twilio_direction}"
    )

    conversation = resolve_conversation
    conference_sid = ensure_conference_sid!(conversation)

    render xml: conference_twiml(conference_sid, agent_leg?(twilio_from))
  end

  def conference_status
    event = mapped_conference_event
    return head :no_content unless event

    conversation = find_conversation_for_conference!(
      friendly_name: params[:FriendlyName],
      call_sid: twilio_call_sid
    )

    Voice::Conference::Manager.new(
      conversation: conversation,
      event: event,
      call_sid: twilio_call_sid,
      participant_label: participant_label
    ).process

    head :no_content
  end

  private

  def twilio_call_sid
    params[:CallSid]
  end

  def twilio_from
    params[:From].to_s
  end

  def twilio_to
    params[:To]
  end

  def twilio_direction
    @twilio_direction ||= (params['Direction'] || params['CallDirection']).to_s
  end

  def mapped_conference_event
    event = params[:StatusCallbackEvent].to_s
    CONFERENCE_EVENT_PATTERNS.each do |pattern, mapped|
      return mapped if event.match?(pattern)
    end
    nil
  end

  def agent_leg?(from_number)
    from_number.start_with?('client:')
  end

  def resolve_conversation
    return find_conversation_for_agent if agent_leg?(twilio_from)

    case twilio_direction
    when 'inbound'
      Voice::InboundCallBuilder.perform!(
        account: current_account,
        inbox: inbox,
        from_number: twilio_from,
        call_sid: twilio_call_sid
      )
    when 'outbound-api', 'outbound-dial'
      sync_outbound_leg(
        call_sid: twilio_call_sid,
        from_number: twilio_from,
        direction: twilio_direction
      )
    else
      raise ArgumentError, "Unsupported Twilio direction: #{twilio_direction}"
    end
  end

  def find_conversation_for_agent
    if params[:conversation_id].present?
      current_account.conversations.find_by!(display_id: params[:conversation_id])
    else
      current_account.conversations.find_by!(identifier: twilio_call_sid)
    end
  end

  def sync_outbound_leg(call_sid:, from_number:, direction:)
    parent_sid = params['ParentCallSid'].presence
    lookup_sid = direction == 'outbound-dial' ? parent_sid || call_sid : call_sid
    conversation = current_account.conversations.find_by!(identifier: lookup_sid)

    Voice::CallSessionSyncService.new(
      conversation: conversation,
      call_sid: call_sid,
      message_call_sid: conversation.identifier,
      leg: {
        from_number: from_number,
        to_number: twilio_to,
        direction: 'outbound'
      }
    ).perform
  end

  def ensure_conference_sid!(conversation)
    attrs = conversation.additional_attributes || {}
    attrs['conference_sid'] ||= Voice::Conference::Name.for(conversation)
    conversation.update!(additional_attributes: attrs)
    attrs['conference_sid']
  end

  def conference_twiml(conference_sid, agent_leg)
    Twilio::TwiML::VoiceResponse.new.tap do |response|
      response.dial do |dial|
        dial.conference(
          conference_sid,
          start_conference_on_enter: agent_leg,
          end_conference_on_exit: false,
          status_callback: conference_status_callback_url,
          status_callback_event: 'start end join leave',
          status_callback_method: 'POST',
          participant_label: agent_leg ? 'agent' : 'contact'
        )
      end
    end.to_s
  end

  def conference_status_callback_url
    phone_digits = inbox_channel.phone_number.delete_prefix('+')
    Rails.application.routes.url_helpers.twilio_voice_conference_status_url(phone: phone_digits)
  end

  def find_conversation_for_conference!(friendly_name:, call_sid:)
    name = friendly_name.to_s
    scope = current_account.conversations

    if name.present?
      conversation = scope.where("additional_attributes->>'conference_sid' = ?", name).first
      return conversation if conversation
    end

    scope.find_by!(identifier: call_sid)
  end

  def set_inbox!
    digits = params[:phone].to_s.gsub(/\D/, '')
    e164 = "+#{digits}"
    channel = Channel::Voice.find_by!(phone_number: e164)
    @inbox = channel.inbox
  end

  def current_account
    @current_account ||= inbox_account
  end

  def participant_label
    params[:ParticipantLabel].to_s
  end

  attr_reader :inbox

  delegate :account, :channel, to: :inbox, prefix: true
end
