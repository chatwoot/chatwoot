module Whatsapp::BaileysHandlers::GroupsUpdate
  include Whatsapp::BaileysHandlers::Helpers
  include Whatsapp::BaileysHandlers::Concerns::GroupContactMessageHandler
  include Whatsapp::BaileysHandlers::Concerns::GroupEventHelper

  TRACKED_SETTINGS = %w[restrict announce memberAddMode joinApprovalMode].freeze

  private

  def process_groups_update
    updates = processed_params[:data]
    return if updates.blank?

    updates.each { |update| process_single_group_update(update) }
  end

  def process_single_group_update(update)
    group_jid = update[:id]
    return if group_jid.blank?

    with_contact_lock(group_jid) do
      group_contact_inbox = find_or_create_group_contact_inbox_by_jid(group_jid)
      conversation = find_or_create_group_conversation(group_contact_inbox)
      author_name = resolve_author_name(update[:author])

      update_group_subject(group_contact_inbox, update[:subject], conversation, author_name) if update.key?(:subject)
      update_group_description(conversation, update, author_name) if update.key?(:desc)
      persist_invite_code_update(conversation, update) if update.key?(:inviteCode)
      create_group_activity(conversation, 'invite_link_reset', author_name: author_name) if update.key?(:inviteCode)
      persist_settings_changes(conversation, update)
      process_group_settings_changes(conversation, update, author_name)

      dispatch_group_synced_event(group_contact_inbox.contact)
    end
  end

  def update_group_subject(group_contact_inbox, subject, conversation, author_name)
    return if subject.blank?

    contact = group_contact_inbox.contact
    contact.update!(name: subject)

    create_group_activity(conversation, 'subject_changed', author_name: author_name, value: subject)
  end

  def update_group_description(conversation, update, author_name)
    desc = update[:desc]
    contact = conversation.contact

    current_attrs = contact.additional_attributes || {}
    new_attrs = current_attrs.merge('description' => desc.presence)
    contact.update!(additional_attributes: new_attrs) if current_attrs != new_attrs

    if desc.present?
      create_group_activity(conversation, 'description_changed', author_name: author_name)
    else
      create_group_activity(conversation, 'description_removed', author_name: author_name)
    end
  end

  def process_group_settings_changes(conversation, update, author_name)
    TRACKED_SETTINGS.each do |setting|
      next unless update.key?(setting.to_sym)

      value = update[setting.to_sym]
      setting_key = setting.underscore
      i18n_key = value ? "#{setting_key}_enabled" : "#{setting_key}_disabled"

      create_group_activity(conversation, i18n_key, author_name: author_name)
    end
  end

  def persist_settings_changes(conversation, update)
    contact = conversation.contact
    settings = {}
    TRACKED_SETTINGS.each do |setting|
      next unless update.key?(setting.to_sym)

      settings[setting.underscore] = update[setting.to_sym]
    end
    return if settings.blank?

    new_attrs = (contact.additional_attributes || {}).merge(settings)
    contact.update!(additional_attributes: new_attrs) if new_attrs != contact.additional_attributes
  end

  def persist_invite_code_update(conversation, update)
    contact = conversation.contact
    invite_code = update[:inviteCode]
    return if invite_code.blank?

    new_attrs = (contact.additional_attributes || {}).merge('invite_code' => invite_code)
    contact.update!(additional_attributes: new_attrs) if new_attrs != contact.additional_attributes
  end
end
