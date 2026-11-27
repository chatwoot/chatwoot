# Asks Jev whether a Captain reply that has not been sent yet tells the customer that a human agent is taking over now.
# The question and its criteria were validated on production replies, so change them only with a new evaluation.
class Captain::Conversation::TransferPromiseCheck
  FEATURE = 'captain_transfer_promise_check'.freeze
  MODE_CONFIG = 'CAPTAIN_TRANSFER_PROMISE_CHECK_MODE'.freeze
  OFF = 'off'.freeze
  SHADOW = 'shadow'.freeze
  HANDOFF = 'handoff'.freeze
  THRESHOLD = 0.5
  CONTEXT_MESSAGES = 6
  CHARACTER_LIMIT = 2000
  QUESTION = {
    type: 'noul',
    instructions: 'Does `reply` tell the customer that this conversation is being handed to a human agent now? ' \
                  '`conversation.messages` is the conversation before the reply, ending with the customer\'s latest message.',
    criteria: {
      'true' => 'The reply states, without any condition, that the customer is being transferred, connected, or handed over, ' \
                'or is about to be, to a human agent or team who will continue this conversation.',
      'false' => 'The reply only offers a human agent or asks whether the customer wants one; says it will hand over only if ' \
                 'something happens later or after the customer sends more information; tells the customer to contact a person or ' \
                 'team somewhere else; describes what another team, provider, or process will do; says it forwarded or will forward ' \
                 'information without handing over the conversation; or does not mention a human taking over.'
    }
  }.freeze

  pattr_initialize [:conversation!, :reply!]

  def self.mode
    return OFF if Captain::JevClient.api_key.blank?

    GlobalConfigService.load(MODE_CONFIG, OFF)
  end

  # Returns false when Jev cannot answer, so a Jev outage or a spent Jev quota never blocks a reply.
  def promised?
    probability = ask
    promised = probability >= THRESHOLD
    log_promise(probability) if promised
    promised
  rescue CustomExceptions::JevQuotaError => e
    Rails.logger.warn("[CAPTAIN][TransferPromiseCheck] Skipped for account=#{conversation.account_id}: #{e.message}")
    false
  rescue Captain::JevClient::HTTPError, Faraday::Error, ArgumentError, TypeError => e
    # ArgumentError and TypeError mean Jev returned no number.
    ChatwootExceptionTracker.new(e, account: conversation.account).capture_exception
    false
  end

  private

  def ask
    body = Captain::JevClient.request_body(model: Captain::JevClient::DEFAULT_MODEL, state: state, questions: { transfer: QUESTION })
    response = Captain::JevClient.new(account_id: conversation.account_id, conversation_id: conversation.display_id, feature: FEATURE)
                                 .call(body: body)
    Float(response.dig('answers', 'transfer', 'noul'))
  end

  def state
    { conversation: { messages: earlier_messages }, reply: reply }
  end

  def earlier_messages
    conversation.messages
                .where(message_type: Captain::ConversationTranscript::MESSAGE_TYPES, private: false)
                .reorder(id: :desc)
                .limit(CONTEXT_MESSAGES)
                .filter_map { |message| Captain::ConversationTranscript.entry(message, CHARACTER_LIMIT) }
                .reverse
  end

  def log_promise(probability)
    Rails.logger.info({
      event: 'captain_transfer_promise_detected', mode: self.class.mode, account_id: conversation.account_id,
      conversation_id: conversation.id, conversation_display_id: conversation.display_id, probability: probability
    }.to_json)
  end
end
