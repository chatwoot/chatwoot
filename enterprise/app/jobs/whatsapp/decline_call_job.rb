class Whatsapp::DeclineCallJob < ApplicationJob
  class DeclineFailed < StandardError; end

  TRANSPORT_ERRORS = [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, SocketError].freeze

  queue_as :critical
  retry_on DeclineFailed, *TRANSPORT_ERRORS, wait: 5.seconds, attempts: 6 do |job, error|
    Rails.logger.warn "[WHATSAPP CALL] Gave up declining call #{job.arguments.last}: #{error.message}"
  end

  def perform(inbox, provider_call_id)
    declined = inbox.channel.provider_service.reject_call(provider_call_id)
    raise DeclineFailed, "Meta did not decline call #{provider_call_id}" unless declined
  end
end
