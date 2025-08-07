class ConversationBuilder
  pattr_initialize [:params!, :contact_inbox!]

  def perform
    Rails.logger.info "[ConversationBuilder] Starting conversation creation - contact_inbox_id: #{@contact_inbox.id}, contact_id: #{@contact_inbox.contact_id}, inbox_id: #{@contact_inbox.inbox_id}"

    result = look_up_exising_conversation || create_new_conversation

    Rails.logger.info "[ConversationBuilder] Conversation creation completed - id: #{result.id}, #{result.persisted? && result.created_at > 1.second.ago ? 'created new' : 'found existing'}"
    result
  rescue StandardError => e
    Rails.logger.error "[ConversationBuilder] Conversation creation failed - error: #{e.message}, backtrace: #{e.backtrace.first(3).join(', ')}"
    raise e
  end

  private

  def look_up_exising_conversation
    return unless @contact_inbox.inbox.lock_to_single_conversation?

    Rails.logger.debug '[ConversationBuilder] Looking up existing conversation for locked inbox'

    existing_conversation = @contact_inbox.conversations.last

    if existing_conversation
      Rails.logger.info "[ConversationBuilder] Found existing conversation - id: #{existing_conversation.id}"
    else
      Rails.logger.debug '[ConversationBuilder] No existing conversation found'
    end

    existing_conversation
  end

  def create_new_conversation
    Rails.logger.info '[ConversationBuilder] Creating new conversation with params: ' \
                      "#{conversation_params.except(:additional_attributes, :custom_attributes).inspect}"

    conversation = ::Conversation.create!(conversation_params)

    Rails.logger.info "[ConversationBuilder] New conversation created successfully - id: #{conversation.id}, display_id: #{conversation.display_id}"
    conversation
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[ConversationBuilder] Conversation creation failed - validation errors: #{e.record.errors.full_messages.join(', ')}"
    raise e
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
