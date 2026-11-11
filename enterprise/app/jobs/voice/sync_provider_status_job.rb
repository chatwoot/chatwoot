# Twilio can send status callbacks before the outbound call row commits.
class Voice::SyncProviderStatusJob < ApplicationJob
  queue_as :high

  ANSWERED_STATUSES = %w[in-progress completed].freeze

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio? || (call.terminal? && !missing_start?(call) && !call.unanswered_by_failed_join?)

    twilio_call = call.inbox.channel.client.calls(call.provider_call_id).fetch
    replay(call, twilio_call)
    fill_start(call, twilio_call) if ANSWERED_STATUSES.include?(twilio_call.status)
  end

  private

  # Replaying the answer first preserves start time when the fetched call is already completed.
  def replay(call, twilio_call)
    apply(call, 'in-progress', 'Timestamp' => twilio_call.start_time.iso8601) if twilio_call.status == 'completed' && twilio_call.start_time
    apply(call, twilio_call.status, timing(twilio_call))
  end

  def missing_start?(call)
    call.status == 'completed' && call.started_at.nil?
  end

  def fill_start(call, twilio_call)
    return unless twilio_call.start_time

    call.with_lock do
      next unless missing_start?(call)

      call.update!(started_at: twilio_call.start_time, duration_seconds: call.duration_seconds || twilio_call.duration&.to_i)
      # Touching the message broadcasts the updated call timing.
      call.message&.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def apply(call, status, payload)
    Voice::StatusUpdateService.new(account: call.account, call_sid: call.provider_call_id, call_status: status, payload: payload).perform
  end

  def timing(twilio_call)
    moment = twilio_call.end_time || twilio_call.start_time
    { 'Timestamp' => moment&.iso8601, 'CallDuration' => twilio_call.duration }.compact
  end
end
