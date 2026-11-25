# The chat list is not refreshed by a message update.
#
# `MESSAGE_UPDATED` only reaches the open thread, so a message mutated in place (an
# edit, a reaction swapped for another, a message deleted from the phone) leaves the
# conversation card in the list showing what it used to say until something else
# updates that conversation. Touching `updated_at` alongside the event is what also
# lets the frontend drop cables that arrive out of order.
module Whatsapp::Session::Inbound::ChatList
  module_function

  def refresh(conversation)
    return if conversation.blank?

    conversation.update_columns(updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    conversation.dispatch_conversation_updated_event
  end
end
