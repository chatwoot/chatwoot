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
    event = call_payload[:event]

    case event
    when 'call_connect'
      handle_call_connect(call_payload)
    when 'call_terminate'
      handle_call_terminate(call_payload)
    end
  end

  def handle_call_connect(call_payload)
    contact = find_or_create_contact("+#{call_payload[:from]}")
    return unless contact

    conversation = find_or_create_conversation(contact)
    return unless conversation

    direction = call_payload.fetch(:direction, 'inbound')
    wa_call = create_call_record(call_payload, conversation, direction)
    create_call_activity_message(conversation, 'incoming_call', direction)
    broadcast_incoming_call(wa_call, contact, call_payload.dig(:session, :sdp))
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn "[WHATSAPP CALL] Duplicate call_id received: #{call_payload[:id]}"
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
    when 'call_ended'
      formatted = format_duration(duration)
      "WhatsApp call ended — #{formatted}"
    when 'call_missed'
      'Missed WhatsApp call'
    else
      'WhatsApp call'
    end
  end

  def format_duration(seconds)
    return '0s' if seconds.nil? || seconds.zero?

    minutes = seconds / 60
    secs = seconds % 60
    minutes.positive? ? "#{minutes}m #{secs}s" : "#{secs}s"
  end

  def broadcast_incoming_call(wa_call, contact, sdp_offer)
    payload = {
      event: 'whatsapp_call.incoming',
      data: {
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
        id: wa_call.id,
        call_id: wa_call.call_id,
        status: wa_call.status,
        duration_seconds: wa_call.duration_seconds,
        conversation_id: wa_call.conversation_id
      }
    }

    ActionCable.server.broadcast("account_#{inbox.account_id}", payload)
  end

  def default_ice_servers
    [{ urls: 'stun:stun.l.google.com:19302' }]
  end
end
