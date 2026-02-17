module Captain::ChatContextResolver
  private

  def resolved_account_id
    @account&.id || @assistant&.account_id
  end

  def resolved_channel_type
    Conversation.find_by(account_id: resolved_account_id, display_id: @conversation_id)&.inbox&.channel_type if @conversation_id
  end
end
