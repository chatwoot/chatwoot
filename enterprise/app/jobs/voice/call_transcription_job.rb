class Voice::CallTranscriptionJob < ApplicationJob
  queue_as :low

  # A recording OpenAI rejects (corrupt/unsupported audio) or credentials it refuses
  # will never succeed on retry — drop the job instead of hammering the API.
  discard_on Faraday::BadRequestError, Faraday::UnauthorizedError do |job, error|
    log_context = {
      call_id: job.arguments.first,
      job_id: job.job_id,
      status_code: error.response&.dig(:status)
    }

    Rails.logger.warn("Discarding call transcription job: #{log_context}")
  end
  retry_on ActiveStorage::FileNotFoundError, wait: 2.seconds, attempts: 3

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank?

    Voice::CallTranscriptionService.new(call: call).perform
  end
end
