module Enterprise::Api::V1::Accounts::Conversations::MessagesController
  def destroy
    audited_message = message

    # Lock before the deleted check so concurrent deletes cannot both write an audit entry.
    audited_message.with_lock do
      next super if audited_message.deleted

      audit_context = message_deletion_audit_context(audited_message)
      super
      create_message_deletion_audit_log(audited_message, audit_context)
    end
  end

  def auto_translate
    return head :forbidden unless Current.account.auto_translate_enabled?

    message_ids = params.require(:message_ids)
    return render_could_not_create_error(I18n.t('errors.auto_translate.invalid_messages')) unless conversation_messages?(message_ids)

    @conversation.messages.where(id: message_ids).find_each do |message|
      Captain::Conversation::ContactMessageTranslationJob.perform_later(message, agent_language)
    end
    head :accepted
  end

  private

  def translation_provider
    Current.account.translation_service
  end

  def translate_message
    return super unless translation_provider == 'captain'

    Captain::Conversation::TranslatorService.new(account: Current.account, conversation_display_id: @conversation.display_id)
                                            .translate(message.content, permitted_params[:target_language])
  end

  def conversation_messages?(message_ids)
    message_ids.is_a?(Array) && @conversation.messages.where(id: message_ids).count == message_ids.uniq.size
  end

  def agent_language
    Current.user.ui_settings['locale'].presence || Current.account.locale
  end

  # Snapshot the context before super soft-deletes the message.
  def message_deletion_audit_context(deleted_message)
    {
      'content' => deleted_message.content,
      'conversation_id' => deleted_message.conversation_id,
      'display_id' => deleted_message.conversation.display_id,
      'inbox_id' => deleted_message.inbox_id,
      'sender_type' => deleted_message.sender_type,
      'sender_id' => deleted_message.sender_id
    }
  end

  def create_message_deletion_audit_log(deleted_message, audit_context)
    Enterprise::AuditLog.create!(
      auditable: deleted_message,
      action: 'destroy',
      user: Current.user,
      associated: deleted_message.account,
      remote_address: request.remote_ip,
      audited_changes: audit_context
    )
  end
end
