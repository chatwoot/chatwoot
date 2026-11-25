class Macros::ExecutionService < ActionService
  def initialize(macro, conversation, user)
    super(conversation)
    @macro = macro
    @account = macro.account
    @user = user
    Current.user = user
  end

  def perform
    @macro.actions.each do |action|
      action = action.with_indifferent_access
      begin
        send(action[:action_name], action[:action_params])
      rescue StandardError => e
        # Drop whatever the failed action staged on the record. `update!` leaves
        # its attributes dirty when the save is refused, and the next action
        # would save them too and fail for a reason its own params never asked
        # for. An inbox with `prevent_assignment_takeover` is one way to get
        # here; any rejected save is another.
        @conversation.reload
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def assign_agent(agent_ids)
    agent_ids = agent_ids.map { |id| id == 'self' ? @user.id : id }
    super(agent_ids)
  end

  def add_private_note(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: true }

    # Added reload here to ensure conversation us persistent with the latest updates
    mb = Messages::MessageBuilder.new(@user, @conversation.reload, params)
    mb.perform
  end

  def send_message(message)
    return if conversation_a_tweet?

    params = { content: message[0], private: false }

    # Added reload here to ensure conversation us persistent with the latest updates
    mb = Messages::MessageBuilder.new(@user, @conversation.reload, params)
    mb.perform
  end

  def send_attachment(blob_ids)
    return if conversation_a_tweet?

    blobs = @macro.files.blobs.where(id: blob_ids)

    return if blobs.blank?

    params = { content: nil, private: false, attachments: blobs }

    # Added reload here to ensure conversation us persistent with the latest updates
    mb = Messages::MessageBuilder.new(@user, @conversation.reload, params)
    mb.perform
  end

  def send_webhook_event(webhook_url)
    payload = webhook_conversation_data.merge(
      event: 'macro.executed',
      macro: { id: @macro.id, name: @macro.name },
      executed_by: @user&.webhook_data
    )
    WebhookJob.perform_later(webhook_url.first, payload)
  end

  # The conversation as this macro's webhook sends it. A personal macro is set up by whoever runs
  # it, so an extension can narrow what that person could not read otherwise.
  def webhook_conversation_data
    @conversation.webhook_data
  end
end

Macros::ExecutionService.include_mod_with('Macros::ExecutionService')
