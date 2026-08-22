class MessageFinder
  MESSAGE_ID_MAX = 2_147_483_647

  def initialize(conversation, params)
    @conversation = conversation
    @params = params
  end

  def perform
    current_messages
  end

  private

  def conversation_messages
    @conversation.messages.includes(:attachments, :sender, sender: { avatar_attachment: [:blob] })
  end

  def messages
    return conversation_messages if @params[:filter_internal_messages].blank?

    conversation_messages.where.not('private = ? OR message_type = ?', true, 2)
  end

  def current_messages
    return messages.none if oversized_message_id?(@params[:after])

    if @params[:after].present? && @params[:before].present?
      apply_private_note_visibility(
        messages_between(normalized_message_id(@params[:after]), @params[:before].to_i)
      )
    elsif @params[:before].present?
      apply_private_note_visibility(messages_before(@params[:before].to_i))
    elsif @params[:after].present?
      apply_private_note_visibility(messages_after(normalized_message_id(@params[:after])))
    else
      apply_private_note_visibility(messages_latest)
    end
  end

  # Dashboard agents: hide private notes the current user must not see.
  # Widget/public paths set filter_internal_messages and already exclude all private notes.
  # When Current.user is blank (Sidekiq jobs, exports, background scripts),
  # return as-is so we don't accidentally hide all private messages in those flows.
  def apply_private_note_visibility(message_list)
    list = Array(message_list)
    return list if Current.user.blank?
    return list if ActiveModel::Type::Boolean.new.cast(@params[:filter_internal_messages])

    conversation = @conversation || list.first&.conversation
    return list if conversation.blank?

    list.select do |message|
      !message.private? || Conversations::PrivateNoteVisibility.allowed?(
        user: Current.user, message: message, conversation: conversation
      )
    end
  end

  def messages_after(after_id)
    messages.reorder('created_at asc').where('id > ?', after_id).limit(100)
  end

  def messages_before(before_id)
    return messages_latest if oversized_message_id?(before_id)

    before_id = normalized_message_id(before_id)
    messages.reorder('created_at desc').where('id < ?', before_id).limit(20).reverse
  end

  def messages_between(after_id, before_id)
    message_scope = messages.reorder('created_at asc').where('id >= ?', after_id)
    message_scope = message_scope.where('id < ?', normalized_message_id(before_id)) unless oversized_message_id?(before_id)
    message_scope.limit(1000)
  end

  def messages_latest
    messages.reorder('created_at desc').limit(20).reverse
  end

  def normalized_message_id(value)
    value.to_i.clamp(0, MESSAGE_ID_MAX)
  end

  def oversized_message_id?(value)
    value.to_i > MESSAGE_ID_MAX
  end
end

MessageFinder.prepend_mod_with('MessageFinder')
