class ConversationBuilder
  pattr_initialize [:params!, :contact_inbox!]

  def perform
    look_up_exising_conversation || create_new_conversation
  end

  private

  def look_up_exising_conversation
    return unless @contact_inbox.inbox.lock_to_single_conversation?

    @contact_inbox.conversations.last
  end

  def create_new_conversation
    ::Conversation.create!(conversation_params)
  end

  def conversation_params
    base_conversation_params.merge(group_params).merge(status_params).compact
  end

  def base_conversation_params
    {
      account_id: @contact_inbox.inbox.account_id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: params[:additional_attributes]&.permit! || {},
      custom_attributes: params[:custom_attributes]&.permit! || {},
      snoozed_until: params[:snoozed_until],
      assignee_id: params[:assignee_id],
      team_id: params[:team_id]
    }
  end

  def group_params
    { group: params[:group], group_source_id: params[:group_source_id], group_title: params[:group_title] }
  end

  def status_params
    params[:status].present? ? { status: params[:status] } : {}
  end
end
