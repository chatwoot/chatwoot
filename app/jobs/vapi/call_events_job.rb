class Vapi::CallEventsJob < ApplicationJob
  queue_as :default

  def perform(payload)
    Vapi::IncomingCallService.new(params: payload).perform
  rescue StandardError => e
    Rails.logger.error "Vapi::CallEventsJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end
end

