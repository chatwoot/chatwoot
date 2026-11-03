# Tells agents about contact details a widget visitor entered that matched an identified contact.
# The visitor did not prove they are that contact, so the details were not saved and the contacts were not merged.
class Conversations::UnverifiedContactNoteService
  pattr_initialize [:conversation!, :matches!]

  def perform
    return if matches.empty?

    Messages::MessageBuilder.new(nil, conversation, { content: content, private: true }).perform
  end

  private

  # Widget requests run in the visitor's locale, but agents read this note
  def content
    I18n.with_locale(conversation.account.locale) do
      I18n.t('conversations.unverified_contact_match.note', matches: matches.map { |match| match_line(match) }.join("\n"))
    end
  end

  def match_line(match)
    contact = match[:contact]
    I18n.t(
      "conversations.unverified_contact_match.#{match[:key]}",
      value: match[:value],
      contact_name: contact.name.presence || contact.email.presence || contact.phone_number.presence || contact.identifier,
      contact_url: "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{contact.account_id}/contacts/#{contact.id}"
    )
  end
end
