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
    Rails.logger.info(
      "TWILIO_VOICE_TWIML account=#{current_account.id} call_sid=#{twilio_call_sid} from=#{twilio_from} direction=#{twilio_direction}"
    )

    call = resolve_call
    render xml: conference_twiml(call)
  end

  def conference_status
    event = mapped_conference_event
    if event.nil?
      Rails.logger.info(
        "TWILIO_VOICE_CONFERENCE_UNMAPPED_EVENT account=#{current_account.id} event=#{params[:StatusCallbackEvent]} call_sid=#{twilio_call_sid}"
      )
      return head :no_content
    end

    call = find_call_for_conference!(params[:FriendlyName], twilio_call_sid)
    persist_twilio_conference_sid!(call, params[:ConferenceSid])

    Voice::Conference::Manager.new(
      call: call,
      event: event,
      participant_label: participant_label
    ).process

    head :no_content
  end

  def recording_status
    Voice::RecordingStatusService.new(
      account: current_account,
      payload: params.to_unsafe_h
    ).perform

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

  def resolve_call
    return find_call_for_agent if agent_leg?(twilio_from)

    case twilio_direction
    when 'inbound'
      Voice::InboundCallBuilder.perform!(
        account: current_account,
        inbox: inbox,
        from_number: twilio_from,
        call_sid: twilio_call_sid
      )
    when 'outbound-api', 'outbound-dial'
      sync_outbound_leg(call_sid: twilio_call_sid, direction: twilio_direction)
    else
      raise ArgumentError, "Unsupported Twilio direction: #{twilio_direction}"
    end
  end

  def find_call_for_agent
    sid = params[:call_sid].presence
    raise ArgumentError, 'call_sid is required for agent leg' if sid.blank?

    inbox_calls.find_by!(provider_call_id: sid)
  end

  def sync_outbound_leg(call_sid:, direction:)
    parent_sid = params['ParentCallSid'].presence
    lookup_sid = direction == 'outbound-dial' ? parent_sid || call_sid : call_sid
    call = inbox_calls.find_by!(provider_call_id: lookup_sid)

    call.update!(parent_call_sid: parent_sid) if parent_sid.present? && call.parent_call_sid != parent_sid
    call
  end

  def inbox_calls
    Call.where(inbox_id: inbox.id, provider: :twilio)
  end

  def conference_twiml(call)
    conference_sid = ensure_conference_sid!(call)

    Twilio::TwiML::VoiceResponse.new.tap do |response|
      response.dial do |dial|
        dial.conference(
          conference_sid,
          start_conference_on_enter: agent_leg?(twilio_from),
          end_conference_on_exit: false,
          record: 'record-from-start',
          recording_status_callback: recording_status_callback_url,
          recording_status_callback_event: 'completed',
          recording_status_callback_method: 'POST',
          status_callback: conference_status_callback_url,
          status_callback_event: 'start end join leave',
          status_callback_method: 'POST',
          participant_label: participant_label_for(twilio_from)
        )
      end
    end.to_s
  end

  def ensure_conference_sid!(call)
    return call.conference_sid if call.conference_sid.present?

    call.update!(conference_sid: call.default_conference_sid)
    call.conference_sid
  end

  def participant_label_for(from_number)
    return from_number.delete_prefix('client:') if from_number.start_with?('client:')

    'contact'
  end

  def conference_status_callback_url
    phone_digits = inbox_channel.phone_number.delete_prefix('+')
    Rails.application.routes.url_helpers.twilio_voice_conference_status_url(phone: phone_digits)
  end

  def recording_status_callback_url
    phone_digits = inbox_channel.phone_number.delete_prefix('+')
    Rails.application.routes.url_helpers.twilio_voice_recording_status_url(phone: phone_digits)
  end

  def find_call_for_conference!(friendly_name, call_sid)
    name = friendly_name.to_s
    call = inbox_calls.by_conference_sid(name).first if name.present?
    call || inbox_calls.find_by!(provider_call_id: call_sid)
  end

  # Twilio's recording webhook only sends its internal ConferenceSid (CF...),
  # not our FriendlyName. Persist Twilio's id the first time we see it on a
  # conference event so the recording lookup can match later.
  def persist_twilio_conference_sid!(call, sid)
    return if sid.blank?
    return if call.twilio_conference_sid == sid

    call.update!(twilio_conference_sid: sid)
  end

  def set_inbox!
    digits = params[:phone].to_s.gsub(/\D/, '')
    phone_number = "+#{digits}"
    channel = Channel::TwilioSms.find_by!(phone_number: phone_number)
    raise ActiveRecord::RecordNotFound, "Voice not enabled for #{phone_number}" unless channel.voice_enabled?

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
