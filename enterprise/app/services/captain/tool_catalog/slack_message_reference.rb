class Captain::ToolCatalog::SlackMessageReference
  PURPOSE = 'captain_slack_message_reference'.freeze
  TTL = 24.hours
  CHANNEL_ID = /\A[CGD][A-Z0-9]+\z/
  TIMESTAMP = /\A\d{10,}\.\d{6}\z/

  def generate(account_id:, conversation_id:, channel:, timestamp:)
    raise ArgumentError, 'invalid Slack message identity' unless valid_identity?(channel, timestamp)

    verifier.generate(
      { 'account_id' => account_id, 'conversation_id' => conversation_id, 'channel' => channel, 'timestamp' => timestamp },
      expires_in: TTL,
      purpose: PURPOSE
    )
  end

  def resolve(reference:, account_id:, conversation_id:)
    payload = verifier.verified(reference, purpose: PURPOSE)
    return {} unless payload.is_a?(Hash) && payload['account_id'] == account_id && payload['conversation_id'] == conversation_id
    return {} unless valid_identity?(payload['channel'], payload['timestamp'])

    payload.slice('channel', 'timestamp')
  end

  private

  def valid_identity?(channel, timestamp)
    CHANNEL_ID.match?(channel.to_s) && TIMESTAMP.match?(timestamp.to_s)
  end

  def verifier
    Rails.application.message_verifier(PURPOSE)
  end
end
