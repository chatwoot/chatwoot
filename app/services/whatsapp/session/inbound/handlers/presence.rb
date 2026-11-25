# Typing and recording indicators, and the online/offline signal that turns them off.
#
# Both are gated by `presence_subscribe`: subscribing to a contact's presence is what
# makes WhatsApp send these at all, and an operator who did not opt in should not have
# the dashboard reacting to them either.
class Whatsapp::Session::Inbound::Handlers::Presence < Whatsapp::Session::Inbound::Handlers::Base
  include Events::Types

  STATES = {
    'composing' => CONVERSATION_TYPING_ON,
    'recording' => CONVERSATION_RECORDING,
    'paused' => CONVERSATION_TYPING_OFF,
    'available' => CONVERSATION_TYPING_OFF,
    'unavailable' => CONVERSATION_TYPING_OFF
  }.freeze

  def perform
    return :ignored unless subscribed?

    event_name = STATES[payload.state]
    return :ignored if event_name.blank?
    return :ignored if chat_presence? && ignorable_chat?(payload.chat)
    # A group types on behalf of one participant; Chatwoot's indicator is per contact.
    return :ignored if chat_presence? && payload.chat.group?

    dispatch(event_name)
  end

  private

  def chat_presence? = payload.is_a?(model::Events::ChatPresence)

  def subscribed?
    channel.provider_config&.dig('presence_subscribe').present?
  end

  def dispatch(event_name)
    contact_inbox = find_contact_inbox
    return :ignored if contact_inbox.nil?

    conversation = inbox.conversations.where(contact_id: contact_inbox.contact_id).where.not(status: :resolved).last
    return :ignored if conversation.nil?

    Rails.configuration.dispatcher.dispatch(
      event_name, Time.zone.now, conversation: conversation, user: contact_inbox.contact, is_private: false
    )
    :handled
  end

  # The party is addressed by LID in one event and by phone in the next, and only one
  # of them may have a contact_inbox yet.
  def find_contact_inbox
    party = chat_presence? ? (payload.sender || model::Party.from_address(payload.chat)) : payload.party
    inbound::ContactLookup.find(inbox: inbox, party: party)
  end
end
