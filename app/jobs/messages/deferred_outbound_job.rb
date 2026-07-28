class Messages::DeferredOutboundJob < ApplicationJob
  queue_as :high

  def perform(conversation_id:, content: nil, blob_ids: nil, user_id: nil, message_source_attrs: nil)
    conversation = Conversation.find_by(id: conversation_id)
    return if conversation.blank?

    unless conversation.can_reply?
      leave_messaging_window_note(conversation, message_source_attrs)
      return
    end

    user = User.find_by(id: user_id) if user_id.present?

    if blob_ids.present?
      send_attachment(conversation, user, Array(blob_ids), message_source_attrs)
    else
      send_text(conversation, user, content, message_source_attrs)
    end
  end

  private

  def leave_messaging_window_note(conversation, message_source_attrs)
    attrs = (message_source_attrs || {}).with_indifferent_access
    rule_id = attrs[:automation_rule_id]
    rule = AutomationRule.find_by(id: rule_id) if rule_id.present?
    account = conversation.account
    locale = account.locale.presence || I18n.default_locale
    name = rule&.name.presence || attrs.dig(:message_source, :name).presence ||
           I18n.t('automation.system_name', locale: locale)
    content = I18n.with_locale(locale) do
      I18n.t('automation.message_skipped_messaging_window', name: name)
    end

    note_attrs = { messaging_window_skipped: true }
    note_attrs.merge!(attrs.slice(:message_source, :automation_rule_id, :automation_rule_name))

    Conversations::SystemAuditNote.perform(
      conversation: conversation,
      content: content,
      content_attributes: note_attrs
    )
  end

  def send_text(conversation, user, content, message_source_attrs)
    return if content.blank?

    params = { content: content, private: false }
    params[:content_attributes] = message_source_attrs if message_source_attrs.present?

    Messages::MessageBuilder.new(user, conversation, params).perform
  end

  def send_attachment(conversation, user, blob_ids, message_source_attrs)
    blobs = ActiveStorage::Blob.where(id: blob_ids)
    return if blobs.blank?

    helper = ActionService.new(conversation)
    params = helper.attachment_message_params(blobs)
    params[:content_attributes] = message_source_attrs if message_source_attrs.present?

    Messages::MessageBuilder.new(user, conversation, params).perform
  end
end
