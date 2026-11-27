# Hands an inbound Twilio call to the inbox's Captain assistant through Vapi, and returns the TwiML that
# connects the caller to it. Returns nil when Captain can't take the call, so the caller rings agents as usual.
class Voice::Captain::CallStarter
  pattr_initialize [:inbox!, :call_sid!, :from!]

  def self.eligible?(inbox:, call_sid:)
    return false unless inbox.channel.captain_answers_calls? && inbox.captain_active?
    return false if Voice::Captain::CallSession.twilio_call_marked?(call_sid)

    Voice::Captain::VapiConfig.configured?
  end

  def perform
    # Marked before anything else, so a redirect back to the call webhook never offers the call to Captain twice
    Voice::Captain::CallSession.mark_twilio_call!(call_sid)
    return unless callable_number?

    conversation = find_or_create_conversation
    return unless conversation.pending? && captain_engages?(conversation)

    start_vapi_call(conversation)
  rescue Voice::Captain::VapiClient::Error, HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout => e
    ChatwootExceptionTracker.new(e, account: inbox.account).capture_exception
    nil
  end

  private

  def start_vapi_call(conversation)
    vapi_call = Voice::Captain::VapiClient.new.create_call(
      customer_number: from,
      assistant: Voice::Captain::AssistantConfig.new(
        assistant: inbox.captain_assistant,
        voice: inbox.channel.captain_voice,
        caller_number: from,
        time_zone: inbox.timezone
      ).to_h
    )
    session = Voice::Captain::CallSession.new(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      conversation_id: conversation.id,
      contact_id: conversation.contact_id,
      twilio_call_sid: call_sid
    )
    session.save!(vapi_call[:id])
    vapi_call[:twiml]
  end

  # The assistant's Schedule and Audience apply to calls as they do to messages: a caller Captain doesn't
  # serve right now is handed to the team, so the conversation opens and the call rings agents
  def captain_engages?(conversation)
    return true if inbox.captain_assistant.engages?(conversation.contact, conversation)

    conversation.open!
    false
  end

  # Vapi needs the caller's number; withheld numbers ring agents
  def callable_number?
    Voice::Provider::Twilio::InboundCaller.new(from: from, call_sid: call_sid, account: inbox.account).build[:source_ids] == [from]
  end

  # Same contact and conversation an agent-answered call would use, so a handoff lands in the conversation Captain wrote to.
  # A conversation an agent already holds stays with the agent.
  def find_or_create_conversation
    contact_inbox = ContactInboxSourceIdResolver.new(
      inbox: inbox,
      source_ids: [from],
      contact_attributes: { name: from, phone_number: from }
    ).perform

    reusable_conversation(contact_inbox) || inbox.account.conversations.create!(
      contact_inbox_id: contact_inbox.id,
      inbox_id: inbox.id,
      contact_id: contact_inbox.contact_id
    )
  end

  def reusable_conversation(contact_inbox)
    conversations = contact_inbox.conversations
    return conversations.last if inbox.lock_to_single_conversation

    conversations.where.not(status: :resolved).last
  end
end
