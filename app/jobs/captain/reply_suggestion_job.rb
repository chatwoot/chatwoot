class Captain::ReplySuggestionJob < ApplicationJob
  EVENT_NAME = 'captain.reply_suggestion.ready'.freeze

  queue_as :default
  # The agent is waiting in the reply box, so a retry minutes later would only deliver a stale draft.
  sidekiq_options retry: false

  def perform(account:, user:, conversation_display_id:, request_id:)
    started_at = Time.current
    log_context = "account=#{account.id} conversation=#{conversation_display_id} request=#{request_id}"
    Rails.logger.info("[CAPTAIN][ReplySuggestionJob] Started #{log_context}")

    result = draft(account, user, conversation_display_id)
    broadcast(account, user, conversation_display_id, request_id, result)

    outcome = if result[:error] then 'error'
              elsif result.key?(:no_reply_reason) then 'no_reply_needed'
              else
                'draft'
              end
    Rails.logger.info("[CAPTAIN][ReplySuggestionJob] Finished #{log_context} outcome=#{outcome} " \
                      "seconds=#{(Time.current - started_at).round(1)}")
  end

  private

  def draft(account, user, conversation_display_id)
    Captain::ReplySuggestionService.new(account: account, conversation_display_id: conversation_display_id, user: user).perform
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: account).capture_exception
    { error: I18n.t('captain.reply_suggestion.failed') }
  end

  def broadcast(account, user, conversation_display_id, request_id, result)
    payload = {
      account_id: account.id,
      conversation_id: conversation_display_id,
      request_id: request_id,
      message: result[:message],
      follow_up_context: result[:follow_up_context],
      no_reply_reason: result[:no_reply_reason],
      error: result[:error]
    }.compact
    ActionCableBroadcastJob.perform_later([user.pubsub_token], EVENT_NAME, payload)
  end
end
