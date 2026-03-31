# frozen_string_literal: true

class AgentBots::ReengagementService
  def initialize(reengagement)
    @reengagement   = reengagement
    @conversation   = reengagement.conversation
    @agent_bot      = reengagement.agent_bot
    @contact        = @conversation.contact
  end

  def execute
    return suppress_for_sequence if active_sequence?
    return cancel(:cancelled_reply)  if should_stop_on_resolved?
    return cancel(:cancelled_reply)  if should_stop_on_agent_assigned?
    return cancel(:cancelled_reply)  if client_replied_since_trigger? && @reengagement.stop_on_any_reply?
    return cancel_keyword(matched_keyword) if (matched_keyword = detect_stop_keyword)

    fire_webhook
    completed = @reengagement.advance!

    Rails.logger.info(
      "ReengagementService: fired attempt #{@reengagement.current_attempt} " \
      "for conversation #{@conversation.id} (completed: #{completed})"
    )
  end

  private

  # ─── Stop condition checks ───────────────────────────────────────────

  def active_sequence?
    ConversationFollowUp.where(conversation_id: @conversation.id, status: 'active').exists?
  end

  def should_stop_on_resolved?
    @reengagement.stop_on_resolved? && @conversation.resolved?
  end

  def should_stop_on_agent_assigned?
    @reengagement.stop_on_agent_assigned? && @conversation.assignee_id.present?
  end

  def client_replied_since_trigger?
    @conversation.messages
                 .where(message_type: :incoming)
                 .where('created_at > ?', @reengagement.trigger_started_at)
                 .exists?
  end

  def detect_stop_keyword
    phrases, case_insensitive = @reengagement.stop_keywords
    return nil if phrases.blank?

    last_incoming = @conversation.messages
                                 .where(message_type: :incoming)
                                 .where('created_at > ?', @reengagement.trigger_started_at)
                                 .order(created_at: :desc)
                                 .first

    return nil unless last_incoming&.content.present?

    text = case_insensitive ? last_incoming.content.downcase : last_incoming.content

    phrases.find do |phrase|
      needle = case_insensitive ? phrase.downcase : phrase
      text.include?(needle)
    end
  end

  # ─── Actions ─────────────────────────────────────────────────────────

  def suppress_for_sequence
    sequence_id = ConversationFollowUp
                    .where(conversation_id: @conversation.id, status: 'active')
                    .pick(:lead_follow_up_sequence_id)
    @reengagement.suppress!(sequence_id: sequence_id)
  end

  def cancel(status_symbol)
    @reengagement.cancel!(reason: status_symbol.to_s)
  end

  def cancel_keyword(phrase)
    @reengagement.cancel!(
      reason: 'cancelled_keyword',
      extra_meta: { 'matched_keyword' => phrase }
    )
  end

  def fire_webhook
    config   = @reengagement.reengagement_config
    attempts = config['attempts'] || []

    reactivation_count = @reengagement.metadata&.dig('reactivation_count').to_i
    idempotency_key = Digest::SHA256.hexdigest(
      "reengagement-#{@reengagement.id}-attempt-#{@reengagement.current_attempt}-reactivation-#{reactivation_count}"
    )

    payload = {
      event: 'proactive_reengagement',
      idempotency_key: idempotency_key,
      attempt: @reengagement.current_attempt + 1,
      max_attempts: attempts.length,
      trigger_started_at: @reengagement.trigger_started_at&.iso8601,
      conversation: @conversation.webhook_data,
      account: { id: @conversation.account_id, name: @conversation.account.name },
      agent_bot_config: {
        assistant_config: @agent_bot.assistant_config,
        agent_behavior_config: @agent_bot.agent_behavior_config,
        has_openai_api_key: @agent_bot.has_openai_api_key?,
        has_google_api_key: @agent_bot.has_google_api_key?,
        has_pinecone_api_key: @agent_bot.account&.pinecone_api_key.present?
      }
    }

    AgentBots::WebhookJob.perform_later(
      @agent_bot.outgoing_url,
      payload,
      :proactive_reengagement,
      idempotency_key
    )
  end
end
