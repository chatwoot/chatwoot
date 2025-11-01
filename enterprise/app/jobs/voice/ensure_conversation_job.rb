class Voice::EnsureConversationJob < ApplicationJob
  queue_as :default

  def perform(account_id:, inbox_id:, from_number:, to_number:, call_sid:)
    account = Account.find(account_id)
    inbox = account.inboxes.find(inbox_id)

    Voice::CallOrchestratorService.new(
      account: account,
      inbox: inbox,
      direction: :inbound,
      phone_number: from_number,
      call_sid: call_sid
    ).inbound!
  rescue StandardError => e
    Rails.logger.error("VOICE_ENSURE_CONVERSATION_JOB_ERROR account=#{account_id} inbox=#{inbox_id} call_sid=#{call_sid} error=#{e.class}: #{e.message}")
    Sentry.capture_exception(e) if defined?(Sentry)
    Raven.capture_exception(e) if defined?(Raven)
    raise
  end
end

