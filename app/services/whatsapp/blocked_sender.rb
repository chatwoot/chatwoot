# The one rule every WhatsApp inbound path applies to a blocked contact, Cloud included
# (`IncomingMessageBaseService#contact_processable?`), and the same one upstream writes
# inline there: what the contact sends is not filed, so it opens no conversation and
# reaches no bot, while the echo of a reply the owner typed on the phone is still filed, or
# the agent's own answer would go missing from the thread. Taking a reaction back is not a
# new message: the paths reconcile it before asking this, as upstream does.
#
# Asked as the first thing after the sender's contact is resolved. Not before: the
# read-only lookup (`Session::Inbound::ContactLookup`) only finds a contact that already
# has a contact_inbox on the inbox, and a blocked contact created through the API has none.
#
# spec/services/whatsapp/blocked_sender_contract_spec.rb lists every inbound entry point and
# fails on one that has not said whether it files what a contact sends.
module Whatsapp::BlockedSender
  module_function

  def silenced?(contact, from_me:)
    contact.blocked? && !from_me
  end
end
