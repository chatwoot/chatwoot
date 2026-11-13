# Finds the Business-Scoped User ID (BSUID) to address a contact by in a WhatsApp inbox when the
# contact has no phone number. BSUIDs are scoped to the business portfolio, so only identities the
# contact already holds in this inbox are considered.
#
# A contact can hold more than one BSUID in an inbox (a rotated alias, or a parent BSUID next to a
# regular one). Chatwoot does not record which of them is current, so #recipient returns nil rather
# than guess.
class Whatsapp::BsuidRecipientFinder
  pattr_initialize [:contact!, :inbox!]

  def source_ids
    @source_ids ||= contact.contact_inboxes.where(inbox_id: inbox.id).pluck(:source_id).select do |source_id|
      source_id.to_s.delete_prefix('whatsapp:').match?(RegexHelper::WHATSAPP_BSUID_REGEX)
    end
  end

  def recipient
    source_ids.first if source_ids.one?
  end
end
