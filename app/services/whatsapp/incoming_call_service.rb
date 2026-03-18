class Whatsapp::IncomingCallService
  pattr_initialize [:inbox!, :params!]

  def perform
    calls = params[:calls]
    return if calls.blank?

    calls.each do |call_payload|
      process_call_event(call_payload.with_indifferent_access)
    end
  end

  private

  def process_call_event(call_payload)
    case call_payload[:event]
    when 'connect' then handle_call_connect(call_payload)
    when 'terminate' then handle_call_terminate(call_payload)
    else Rails.logger.warn "[WHATSAPP CALL] Unknown call event: #{call_payload[:event]}"
    end
  end

  def handle_call_connect(call_payload)
    call_id = call_payload[:id]
    direction = map_direction(call_payload[:direction])

    # For outbound calls, a WhatsappCall record already exists from initiate.
    # Update it instead of creating a duplicate.
    existing_call = WhatsappCall.find_by(call_id: call_id)
    if existing_call
      Rails.logger.info "[WHATSAPP CALL] call_connect for existing call #{call_id} (direction=#{direction})"
      sdp_answer = fix_sdp_setup(call_payload.dig(:session, :sdp))
      existing_call.update!(meta: existing_call.meta.merge('sdp_answer' => sdp_answer))
      broadcast_outbound_call_connected(existing_call, sdp_answer)
      return
    end

    contact = find_or_create_contact("+#{call_payload[:from]}")
    return unless contact

    conversation = find_or_create_conversation(contact)
    return unless conversation

    wa_call = create_call_record(call_payload, conversation, direction)
    create_call_activity_message(conversation, 'incoming_call', direction)
    broadcast_incoming_call(wa_call, contact, call_payload.dig(:session, :sdp))
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn "[WHATSAPP CALL] Duplicate call_id received: #{call_id}"
  end

  def create_call_record(call_payload, conversation, direction)
    WhatsappCall.create!(
      account: inbox.account,
      inbox: inbox,
      conversation: conversation,
      call_id: call_payload[:id],
      direction: direction,
      status: 'ringing',
      meta: { sdp_offer: call_payload.dig(:session, :sdp), ice_servers: default_ice_servers }
    )
  end

  def handle_call_terminate(call_payload)
    call_id = call_payload[:id]
    duration = call_payload[:duration]&.to_i
    end_reason = call_payload[:terminate_reason]

    wa_call = WhatsappCall.find_by(call_id: call_id)
    return unless wa_call

    final_status = wa_call.accepted? ? 'ended' : 'missed'
    wa_call.update!(
      status: final_status,
      duration_seconds: duration,
      end_reason: end_reason
    )

    call_event = duration.to_i.positive? ? 'call_ended' : 'call_missed'
    create_call_activity_message(wa_call.conversation, call_event, wa_call.direction, duration: duration)
    broadcast_call_ended(wa_call)
  end

  def find_or_create_contact(phone_number)
    waid = phone_number.delete('+')

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: waid,
      inbox: inbox,
      contact_attributes: {
        name: phone_number,
        phone_number: phone_number
      }
    ).perform

    contact_inbox&.contact
  end

  def find_or_create_conversation(contact)
    contact_inbox = contact.contact_inboxes.find_by(inbox: inbox)
    return unless contact_inbox

    conversation = contact_inbox.conversations.where.not(status: :resolved).last
    return conversation if conversation

    ::Conversation.create!(
      account_id: inbox.account_id,
      inbox: inbox,
      contact: contact,
      contact_inbox: contact_inbox,
      additional_attributes: { channel: 'whatsapp' }
    )
  end

  def create_call_activity_message(conversation, event, direction, duration: nil)
    content = call_activity_content(event, direction, duration)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content,
      content_attributes: {
        call_event: event,
        call_direction: direction,
        call_duration_seconds: duration
      }
    )
  end

  def call_activity_content(event, direction, duration)
    case event
    when 'incoming_call'
      direction == 'inbound' ? 'Incoming WhatsApp call' : 'Outgoing WhatsApp call'
    when 'call_ended' then "WhatsApp call ended — #{format_duration(duration)}"
    when 'call_missed' then 'Missed WhatsApp call'
    else 'WhatsApp call'
    end
  end

  def format_duration(seconds)
    return '0s' if seconds.nil? || seconds.zero?

    mins, secs = seconds.divmod(60)
    mins.positive? ? "#{mins}m #{secs}s" : "#{secs}s"
  end

  def broadcast_incoming_call(wa_call, contact, sdp_offer)
    payload = {
      event: 'whatsapp_call.incoming',
      data: {
        account_id: inbox.account_id,
        id: wa_call.id,
        call_id: wa_call.call_id,
        direction: wa_call.direction,
        inbox_id: wa_call.inbox_id,
        conversation_id: wa_call.conversation_id,
        caller: {
          name: contact.name,
          phone: contact.phone_number,
          avatar: contact.avatar_url
        },
        sdp_offer: sdp_offer,
        ice_servers: default_ice_servers
      }
    }

    ActionCable.server.broadcast("account_#{inbox.account_id}", payload)
  end

  def broadcast_call_ended(wa_call)
    payload = {
      event: 'whatsapp_call.ended',
      data: {
        account_id: inbox.account_id,
        id: wa_call.id,
        call_id: wa_call.call_id,
        status: wa_call.status,
        duration_seconds: wa_call.duration_seconds,
        conversation_id: wa_call.conversation_id
      }
    }

    ActionCable.server.broadcast("account_#{inbox.account_id}", payload)
  end

  def broadcast_outbound_call_connected(wa_call, sdp_answer)
    payload = {
      event: 'whatsapp_call.outbound_connected',
      data: {
        account_id: inbox.account_id,
        id: wa_call.id,
        call_id: wa_call.call_id,
        conversation_id: wa_call.conversation_id,
        sdp_answer: sdp_answer
      }
    }

    ActionCable.server.broadcast("account_#{inbox.account_id}", payload)
  end

  # Meta sends "USER_INITIATED" / "BUSINESS_INITIATED", map to our model values
  def map_direction(raw_direction)
    return 'outbound' if raw_direction&.upcase == 'BUSINESS_INITIATED'

    'inbound'
  end

  def default_ice_servers
    [{ urls: 'stun:stun.l.google.com:19302' }]
  end

  def fix_sdp_setup(sdp)
    sdp.present? ? sdp.gsub('a=setup:actpass', 'a=setup:active') : sdp
  end
end
