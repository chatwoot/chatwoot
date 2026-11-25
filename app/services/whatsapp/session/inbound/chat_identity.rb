# Who a chat belongs to, and every key that names it.
#
# Shared by the live path and the history import so the two cannot drift: a message that
# resolves to one contact when it arrives and to another when it is imported would file
# the same person twice, and a lock key computed differently in the two places would let
# an import and a live message open a conversation each for the same chat.
module Whatsapp::Session::Inbound::ChatIdentity
  module_function

  # In a 1:1 chat the other side is the chat itself; `sender` is the author, which is the
  # session owner on an echo and therefore not who the conversation belongs to. An
  # incoming message carries the richer Party (phone and LID together), so it wins.
  def peer_party(message)
    return message.sender if message.incoming? && message.sender.present?

    Whatsapp::Session::Model::Party.from_address(message.chat)
  end

  # Every id this chat can be addressed by. WhatsApp names the same 1:1 peer by phone in
  # one event and by LID in the next, and both resolve to one contact: locking only the id
  # this event carries lets a worker holding the other alias run alongside, and each opens
  # a conversation of its own.
  #
  # Every ninth-digit form as well: WhatsApp reports a Brazilian or Argentinian line with
  # or without the extra digit, `ContactResolver` files both under one contact, and two
  # keys differing by that digit would not serialize against each other.
  def lock_ids(message)
    return [message.chat.id] if message.group?

    party = peer_party(message)
    [message.chat.id, party&.lid, *Whatsapp::Session::PhoneMatch.variants(party&.phone)]
  end
end
