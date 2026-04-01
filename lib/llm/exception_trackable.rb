module Llm::ExceptionTrackable
  private

  def capture_llm_exception(error, credential:)
    return unless credential&.system?

    ChatwootExceptionTracker.new(error, account: exception_tracking_account).capture_exception
  end
end
