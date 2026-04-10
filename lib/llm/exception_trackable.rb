module Llm::ExceptionTrackable
  private

  def capture_llm_exception(error, credential:)
    if credential && credential[:source] == :system
      ChatwootExceptionTracker.new(error, account: exception_tracking_account).capture_exception
    else
      Rails.logger.error("[LLM] account=#{exception_tracking_account&.id} #{error.class}: #{error.message}")
    end
  end
end
