module Whatsapp::BaileysHandlers::GroupParticipantsUpdate
  include Whatsapp::BaileysHandlers::Helpers
  include Whatsapp::BaileysHandlers::Concerns::GroupContactMessageHandler
  include Whatsapp::BaileysHandlers::Concerns::GroupEventHelper

  private

  def process_group_participants_update
    data = processed_params[:data]
    return if data.blank?

    group_jid, author, action, participants = data.values_at(:id, :author, :action, :participants)
    return unless valid_participant_update?(group_jid, action, participants)

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_by_jid(group_jid)
      conversation = find_or_create_group_conversation(group_contact_inbox)
      group_contact = group_contact_inbox.contact

      contacts = participants.filter_map { |participant| find_or_create_participant_contact(participant) }
      return if contacts.empty?

      contacts.each { |contact| apply_participant_action(action, group_contact, contact) }
      create_participant_activity(conversation, action, contacts, author)
      dispatch_group_synced_event(group_contact)

      resolve_conversations_if_inbox_left(action, author, contacts, group_contact_inbox)
    end
  end

  def valid_participant_update?(group_jid, action, participants)
    group_jid.present? && action.present? && participants.present? && action.in?(%w[add remove promote demote])
  end

  def apply_participant_action(action, group_contact, contact)
    case action
    when 'add'
      add_group_member(group_contact, contact, role: :member)
    when 'remove'
      remove_group_member(group_contact, contact)
    when 'promote'
      update_group_member_role(group_contact, contact, :admin)
    when 'demote'
      update_group_member_role(group_contact, contact, :member)
    end
  end

  def create_participant_activity(conversation, action, contacts, author_jid)
    locale = inbox.account.locale || I18n.default_locale
    action = resolve_effective_action(action, author_jid, contacts)

    content = I18n.with_locale(locale) { build_activity_content(action, contacts, resolve_author_name(author_jid)) }

    conversation.messages.create!(
      account_id: conversation.account_id,
      inbox_id: conversation.inbox_id,
      message_type: :activity,
      content: content
    )
  end

  def resolve_effective_action(action, author_jid, contacts)
    return 'join' if action == 'add' && author_jid.blank?
    return 'leave' if action == 'remove' && author_is_participant?(author_jid, contacts)

    action
  end

  def author_is_participant?(author_jid, contacts)
    return false if author_jid.blank?

    author_lid = author_jid.split('@').first
    contacts.any? { |c| c.identifier&.start_with?(author_lid) || c.phone_number&.delete('+') == author_lid }
  end

  def build_activity_content(action, contacts, author_name)
    names = contacts.map { |c| c.name.presence || c.phone_number || c.identifier }

    return I18n.t("conversations.activity.group_participants.#{action}", contact_name: names.first) if action.in?(%w[join leave])

    params = { author_name: author_name }

    if names.one?
      params[:contact_name] = names.first
      I18n.t("conversations.activity.group_participants.#{action}.single", **params)
    else
      params[:contact_names] = names[..-2].join(', ')
      params[:last_contact_name] = names.last
      I18n.t("conversations.activity.group_participants.#{action}.multiple", **params)
    end
  end

  def resolve_conversations_if_inbox_left(action, author_jid, contacts, group_contact_inbox)
    return unless action == 'remove'
    return unless inbox_phone_in_participants?(contacts)

    effective_action = resolve_effective_action(action, author_jid, contacts)
    return unless effective_action.in?(%w[leave remove])

    mark_group_as_left(group_contact_inbox.contact)

    group_contact_inbox.conversations.where(status: %i[open pending]).find_each do |conversation|
      conversation.update!(status: :resolved)
    end
  end

  def mark_group_as_left(group_contact)
    new_attrs = (group_contact.additional_attributes || {}).merge('group_left' => true)
    group_contact.update!(additional_attributes: new_attrs) if new_attrs != group_contact.additional_attributes
  end

  def inbox_phone_in_participants?(contacts)
    inbox_phone = inbox.channel.phone_number&.delete('+')
    return false if inbox_phone.blank?

    contacts.any? { |c| c.phone_number&.delete('+') == inbox_phone }
  end
end
