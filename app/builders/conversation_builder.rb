class ConversationBuilder
  pattr_initialize [:params!, :contact_inbox!]

  def perform
    validate_labels
    existing_conversation = look_up_exising_conversation
    return create_new_conversation unless existing_conversation

    existing_conversation.add_labels(params[:labels])
    existing_conversation
  end

  private

  def validate_labels
    return if params[:labels].nil? || (params[:labels].is_a?(Array) && params[:labels].all?(String))

    raise ActionController::ParameterMissing, :labels
  end

  def look_up_exising_conversation
    return unless @contact_inbox.inbox.lock_to_single_conversation?

    @contact_inbox.conversations.last
  end

  def create_new_conversation
    ::Conversation.create!(conversation_params)
  end

  def conversation_params
    additional_attributes = params[:additional_attributes]&.permit! || {}
    custom_attributes = params[:custom_attributes]&.permit! || {}
    status = params[:status].present? ? { status: params[:status] } : {}

    # TODO: temporary fallback for the old bot status in conversation, we will remove after couple of releases
    # commenting this out to see if there are any errors, if not we can remove this in subsequent releases
    # status = { status: 'pending' } if status[:status] == 'bot'
    {
      account_id: @contact_inbox.inbox.account_id,
      inbox_id: @contact_inbox.inbox_id,
      contact_id: @contact_inbox.contact_id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: additional_attributes,
      custom_attributes: custom_attributes,
      snoozed_until: params[:snoozed_until],
      assignee_id: params[:assignee_id],
      team_id: params[:team_id],
      label_list: params[:labels]
    }.merge(status)
  end
end
