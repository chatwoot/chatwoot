# Handles contact details a widget visitor entered that matched an identified contact.
# The visitor did not prove they are that contact, so ContactIdentifyAction did not save the details or merge the contacts.
#
# When the inbox does not require identity validation, the visitor has no identifier of their own and the conversation
# is not linked yet, the conversation is linked to the first matched contact, so agents see it in that contact's history.
# Only the conversation moves. The visitor's contact and contact inbox stay as they are, so the widget session never acts
# as the matched contact. Agents get a private note that lists the matches and says whether the conversation was linked.
class Conversations::UnverifiedContactMatchService
  pattr_initialize [:conversation!, :matches!]

  # Visitors control these values. Removing these characters stops them from adding Markdown links,
  # mention:// URLs that MentionService acts on, or Liquid tags, and keeps them inside their code span.
  UNSAFE_CHARACTERS = '`()[]{}'.freeze

  def perform
    return if matches.empty?
    # The visitor entered the same details again, and the note from the first link already covers them
    return if conversation.contact_id == matches.first[:contact].id

    linked = linkable?
    conversation.update!(contact: matches.first[:contact]) if linked
    Messages::MessageBuilder.new(nil, conversation, { content: content(linked), private: true }).perform
  end

  private

  # The contact inbox always belongs to the visitor, while conversation.contact changes once the conversation is linked
  def linkable?
    visitor_contact = conversation.contact_inbox.contact
    !conversation.inbox.channel.hmac_mandatory && visitor_contact.identifier.blank? && conversation.contact == visitor_contact
  end

  # Widget requests run in the visitor's locale, but agents read this note
  def content(linked)
    note_key = linked ? 'linked_note' : 'note'
    I18n.with_locale(conversation.account.locale) do
      I18n.t("conversations.unverified_contact_match.#{note_key}", matches: matches.map { |match| match_line(match) }.join("\n"))
    end
  end

  def match_line(match)
    contact = match[:contact]
    I18n.t(
      "conversations.unverified_contact_match.#{match[:key]}",
      value: match[:value].delete(UNSAFE_CHARACTERS),
      contact_name: [contact.name, contact.email, contact.phone_number, contact.identifier].compact_blank.first.delete(UNSAFE_CHARACTERS),
      contact_url: "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{contact.account_id}/contacts/#{contact.id}"
    )
  end
end
