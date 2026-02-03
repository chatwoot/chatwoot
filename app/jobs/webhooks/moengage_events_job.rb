class Webhooks::MoengageEventsJob < ApplicationJob
  queue_as :default

  def perform(event_log_id)
    @event_log = MoengageWebhookEventLog.find_by(id: event_log_id)
    return unless @event_log
    return if @event_log.success? # Already processed

    @start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    process_webhook
  rescue StandardError => e
    mark_failed(e.message)
    raise
  end

  private

  def process_webhook
    service = Integrations::Moengage::WebhookProcessorService.new(
      hook: @event_log.hook,
      payload: @event_log.payload.with_indifferent_access,
      event_log: @event_log
    )
    service.perform
  end

  def mark_failed(error_message)
    @event_log.update(
      status: :failed,
      error_message: error_message,
      processing_time_ms: calculate_processing_time
    )
  end

  def calculate_processing_time
    return nil unless @start_time

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_time
    (elapsed * 1000).round
  end
end
