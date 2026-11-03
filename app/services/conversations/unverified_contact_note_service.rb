# Tells agents about contact details a widget visitor entered that matched an identified contact.
# The visitor did not prove they are that contact, so the details were not saved and the contacts were not merged.
class Conversations::UnverifiedContactNoteService
  pattr_initialize [:conversation!, :matches!]

  def perform
    return if matches.empty?

    Messages::MessageBuilder.new(nil, conversation, { content: content, private: true }).perform
  end

  private

  def content
    I18n.t('conversations.unverified_contact_match.note', matches: matches.map { |match| match_line(match) }.join("\n"))
  end

  def match_line(match)
    contact = match[:contact]
    I18n.t(
      "conversations.unverified_contact_match.#{match[:key]}",
      value: match[:value],
      contact_name: contact.name.presence || contact.email,
      contact_url: "#{ENV.fetch('FRONTEND_URL', nil)}/app/accounts/#{contact.account_id}/contacts/#{contact.id}"
    )
  end
end
