module Llm::ExceptionTrackable
  private

  # Records the failure to the Super Admin-visible log (so misconfigurations are
  # queryable and debuggable), and additionally reports system-level failures to
  # Sentry / Rails.logger as before.
  def capture_llm_exception(error, credential:, **attributes)
    account = exception_tracking_account
    Captain::Llm::FailureLogger.record(
      source: attributes[:source] || :chat,
      error: error,
      model: attributes[:model],
      account_id: account&.id,
      conversation_id: attributes[:conversation_id],
      request_messages: attributes[:messages]
    )

    if credential && credential[:source] == :system
      ChatwootExceptionTracker.new(error, account: account).capture_exception
    else
      Rails.logger.error("[LLM] account=#{account&.id} #{error.class}: #{error.message}")
    end
  end
end
