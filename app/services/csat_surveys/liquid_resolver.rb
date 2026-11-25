# Renders an admin-authored `csat_config` value as Liquid against this conversation's drops.
# It sits outside CsatSurveyService because both the WhatsApp template payload and the message
# body need it, and a value that fails to parse must degrade to its literal text rather than
# take the survey down.
class CsatSurveys::LiquidResolver
  pattr_initialize [:conversation!]

  def resolve(value)
    return value if value.blank?

    Liquid::Template.parse(value).render(drops).presence || value
  rescue Liquid::Error
    value
  end

  private

  def drops
    @drops ||= {
      'contact' => ContactDrop.new(conversation.contact),
      'conversation' => ConversationDrop.new(conversation),
      'inbox' => InboxDrop.new(conversation.inbox),
      'account' => AccountDrop.new(conversation.account)
    }
  end
end
