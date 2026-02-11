class Messages::AudioTranscriptionJob < ApplicationJob
  queue_as :low

  discard_on Faraday::BadRequestError do |job, error|
    log_context = {
      attachment_id: job.arguments.first,
      job_id: job.job_id,
      error_message: error.message,
      status_code: error.response&.dig(:status)
    }

    Rails.logger.warn("Discarding audio transcription job due to bad request: #{log_context}")

    next unless defined?(NewRelic::Agent)

    NewRelic::Agent.notice_error(error, custom_params: log_context)
  end
  retry_on ActiveStorage::FileNotFoundError, wait: 2.seconds, attempts: 3

  def perform(attachment_id)
    attachment = Attachment.find_by(id: attachment_id)
    return if attachment.blank?

    Messages::AudioTranscriptionService.new(attachment).perform
  end
end
