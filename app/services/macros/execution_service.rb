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
        execute_action(action)
      rescue StandardError => e
        ChatwootExceptionTracker.new(e, account: @account).capture_exception
      end
    end
  ensure
    Current.reset
  end

  private

  def execute_action(action)
    name = action[:action_name].to_s
    if %w[send_message send_attachment].include?(name)
      send(name, action[:action_params], action[:delivery])
    else
      send(name, action[:action_params])
    end
  end

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

  def send_message(message, delivery = nil)
    return if conversation_a_tweet?

    content = message.is_a?(Array) ? message[0] : message
    schedule_or_send_outbound(
      delivery: delivery,
      content: content,
      user: @user
    ) do
      params = { content: content, private: false }
      Messages::MessageBuilder.new(@user, @conversation.reload, params).perform
    end
  end

  def send_attachment(blob_ids, delivery = nil)
    return if conversation_a_tweet?

    return unless @macro.files.attached?

    blobs = ActiveStorage::Blob.where(id: blob_ids)
    return if blobs.blank?

    schedule_or_send_outbound(
      delivery: delivery,
      blob_ids: blobs.map(&:id),
      user: @user
    ) do
      params = attachment_message_params(blobs)
      Messages::MessageBuilder.new(@user, @conversation.reload, params).perform
    end
  end

  def send_webhook_event(webhook_url)
    payload = @conversation.webhook_data.merge(event: 'macro.executed')
    WebhookJob.perform_later(webhook_url.first, payload)
  end
end
