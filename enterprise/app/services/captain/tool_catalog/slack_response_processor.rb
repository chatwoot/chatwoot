class Captain::ToolCatalog::SlackResponseProcessor
  def initialize(account_id:, conversation_id:)
    @account_id = account_id
    @conversation_id = conversation_id
  end

  def process(operation_key:, result:)
    return result unless %w[reply_to_thread send_message].include?(operation_key)

    payload = result.to_h.deep_dup
    channel = payload['channel']
    timestamp = payload['ts']
    raise Captain::ToolCatalog::ExecutionError.new('invalid_response', 'slack_message_identity_missing') if channel.blank? || timestamp.blank?

    payload['message_reference'] = Captain::ToolCatalog::SlackMessageReference.new.generate(
      account_id: account_id,
      conversation_id: conversation_id,
      channel: channel,
      timestamp: timestamp
    )
    payload
  end

  private

  attr_reader :account_id, :conversation_id
end
