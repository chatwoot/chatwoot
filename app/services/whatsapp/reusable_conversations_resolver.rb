# Picks the conversations an incoming WhatsApp payload is allowed to land on.
#
# Reuse spans the resolved contact inbox plus the contact's phone backed rows. That pair is one person
# under two aliases, which is how a thread opened by an outbound message or a campaign — always keyed on
# the phone number — gets answered once Meta starts identifying the sender by a business scoped user id.
# Two identifier rows on one contact are different people brought together by a dashboard merge, so they
# never share a thread and a reply is never addressed through the other one's source id.
#
# 360Dialog always sends the destination in `to` and cannot address an identifier, so it keeps plain
# contact wide reuse, which lands every message on the phone backed thread it can actually reply through.
class Whatsapp::ReusableConversationsResolver
  pattr_initialize [:inbox!, :contact!, :contact_inbox!, { addressable_identifiers: false }]

  def perform
    conversations = contact.conversations.where(inbox_id: inbox.id)
    return conversations unless addressable_identifiers

    conversations.where(contact_inbox_id: [contact_inbox.id, *phone_contact_inbox_ids])
  end

  private

  def phone_contact_inbox_ids
    inbox.contact_inboxes.where(contact_id: contact.id).pluck(:id, :source_id)
         .filter_map { |id, source_id| id unless source_id.match?(RegexHelper::WHATSAPP_BSUID_REGEX) }
  end
end
