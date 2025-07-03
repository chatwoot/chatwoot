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
    conversation = ::Conversation.create!(conversation_params)

    # Override status if explicitly provided in params
    # This is required because the Conversation model's determine_conversation_status callback
    # automatically sets status to :pending when there's an active bot on the inbox.
    # However, when users manually create conversations (e.g., via the frontend form),
    # they should be able to explicitly set the status to :open to bypass bot handling.
    # We use update_column to avoid triggering callbacks and activity logs since this
    # is just correcting the status to match the user's explicit intent.
    if params[:status].present?
      # rubocop:disable Rails/SkipsModelValidations
      conversation.update_column(:status, params[:status])
      # rubocop:enable Rails/SkipsModelValidations
    end

    conversation
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
      team_id: params[:team_id]
    }.merge(status)
  end
end
