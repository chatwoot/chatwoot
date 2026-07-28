class Voice::CallTranscriptionJob < ApplicationJob
  queue_as :low

  retry_on ActiveStorage::FileNotFoundError, wait: 2.seconds, attempts: 3

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank?

    Voice::CallTranscriptionService.new(call: call).perform
  end
end
