# Tells agents about contact details a widget visitor entered that matched an identified contact.
# The visitor did not prove they are that contact, so the details were not saved.
# linked: true means the conversation was linked to the matched contact without verification.
class Conversations::UnverifiedContactNoteService
  pattr_initialize [:conversation!, :matches!, { linked: false }]

  # Visitors control these values. Removing these characters stops them from adding Markdown links,
  # mention:// URLs that MentionService acts on, or Liquid tags, and keeps them inside their code span.
  UNSAFE_CHARACTERS = '`()[]{}'.freeze

  def perform
    return if matches.empty?

    Messages::MessageBuilder.new(nil, conversation, { content: content, private: true }).perform
  end

  private

  # Widget requests run in the visitor's locale, but agents read this note
  def content
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
