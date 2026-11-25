# The activity messages a group thread shows ("X changed the group name to Y").
#
# The i18n keys are the ones the Baileys layer already writes, so a converted inbox
# keeps rendering its history and its new events the same way.
class Whatsapp::Session::Inbound::GroupActivityWriter
  attr_reader :conversation, :actor

  def initialize(conversation:, actor: nil)
    @conversation = conversation
    @actor = actor
  end

  def write(key, **params)
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: translate("groups_update.#{key}", author_name: author_name, **params)
    )
  end

  def write_participants(action, contacts)
    names = contacts.map { |contact| contact.name.presence || contact.phone_number || contact.identifier }
    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: participant_content(action, names)
    )
  end

  # The name to blame for a change. A group event names its author by LID, which may
  # not be a contact yet: the raw id is a better answer than an empty sentence.
  def author_name
    return translate('groups_update.unknown_author') if actor.blank?

    contact = actor_contact
    contact&.name.presence || contact&.phone_number.presence || actor.name.presence || actor.source_id
  end

  private

  def inbox = conversation.inbox

  # A group event names its author by whichever key WhatsApp felt like using, which is
  # often not the one the contact_inbox is filed under: an exact match prints the raw
  # number in an activity line that has the person's name available.
  def actor_contact
    Whatsapp::Session::Inbound::ContactLookup.contact(inbox: inbox, party: actor)
  end

  def participant_content(action, names)
    return translate("group_participants.#{action}", contact_name: names.first) if action.in?(%w[join leave])

    if names.one?
      translate("group_participants.#{action}.single", author_name: author_name, contact_name: names.first)
    else
      translate("group_participants.#{action}.multiple", author_name: author_name,
                                                         contact_names: names[..-2].join(', '), last_contact_name: names.last)
    end
  end

  def translate(key, **params)
    locale = conversation.account.locale || I18n.default_locale
    I18n.with_locale(locale) { I18n.t("conversations.activity.#{key}", **params) }
  end
end
