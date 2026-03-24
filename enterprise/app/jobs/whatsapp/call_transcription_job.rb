class Whatsapp::CallTranscriptionJob < ApplicationJob
  queue_as :low

  retry_on ActiveStorage::FileNotFoundError, wait: 2.seconds, attempts: 3
  discard_on Faraday::BadRequestError do |job, error|
    Rails.logger.warn("[WHATSAPP CALL] Discarding transcription job: call_id=#{job.arguments.first}, status=#{error.response&.dig(:status)}")
  end

  def perform(whatsapp_call_id)
    wa_call = WhatsappCall.find_by(id: whatsapp_call_id)
    return if wa_call.blank? || !wa_call.recording.attached?

    Whatsapp::CallTranscriptionService.new(wa_call).perform
  end
end
