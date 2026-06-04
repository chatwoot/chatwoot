module Whatsapp::BaileysHandlers::Concerns::GroupEventHelper
  private

  def find_or_create_group_contact_inbox_by_jid(group_jid)
    source_id = group_jid.split('@').first

    ::ContactInboxWithContactBuilder.new(
      source_id: source_id,
      inbox: inbox,
      contact_attributes: {
        name: source_id,
        identifier: group_jid,
        group_type: :group
      }
    ).perform
  end

  def create_group_activity(conversation, action, **params)
    locale = inbox.account.locale || I18n.default_locale

    content = I18n.with_locale(locale) { I18n.t("conversations.activity.groups_update.#{action}", **params) }

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    )
  end

  def resolve_author_name(author_jid)
    return author_jid if author_jid.blank?

    lid = author_jid.split('@').first
    contact_inbox = inbox.contact_inboxes.find_by(source_id: lid)
    resolved_contact = contact_inbox&.contact

    resolved_contact&.name.presence || resolved_contact&.phone_number || lid
  end

  def dispatch_group_synced_event(group_contact)
    group_contact.reload
    Rails.configuration.dispatcher.dispatch(
      Events::Types::CONTACT_GROUP_SYNCED,
      Time.zone.now,
      contact: group_contact
    )
  end
end
