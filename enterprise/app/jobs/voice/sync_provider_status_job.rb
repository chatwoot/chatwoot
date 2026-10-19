# Applies Twilio's current status to an outbound call once its row is visible. The call
# is dialled before its row commits, so a status callback can arrive while there is no
# call to apply it to; reading the status afterwards recovers what that callback carried.
class Voice::SyncProviderStatusJob < ApplicationJob
  queue_as :high

  # Twilio statuses of a call that was answered, whose start time is when that happened
  ANSWERED_STATUSES = %w[in-progress completed].freeze

  def perform(call_id)
    call = Call.find_by(id: call_id)
    return if call.blank? || !call.twilio? || (call.terminal? && !missing_start?(call) && !call.unanswered_by_failed_join?)

    twilio_call = call.inbox.channel.client.calls(call.provider_call_id).fetch
    # The status manager keeps an ended call as it is, apart from an answer that comes in
    # after a failed join ended it unanswered
    replay(call, twilio_call)
    fill_start(call, twilio_call) if ANSWERED_STATUSES.include?(twilio_call.status)
  end

  private

  # A call answered and over by now is taken through its answer first, so it keeps when it
  # started as well as when it ended
  def replay(call, twilio_call)
    apply(call, 'in-progress', 'Timestamp' => twilio_call.start_time.iso8601) if twilio_call.status == 'completed' && twilio_call.start_time
    apply(call, twilio_call.status, timing(twilio_call))
  end

  def missing_start?(call) = call.status == 'completed' && call.started_at.nil?

  # A completed callback that came in after the row committed, before this ran or while it
  # asked Twilio, may have left the call without the answer that came in before it; Twilio
  # still has when it started, and how long it lasted, whether it reported the call live or
  # over. Filled under the row lock, and only where nothing set them.
  def fill_start(call, twilio_call)
    return unless twilio_call.start_time

    call.with_lock do
      next unless missing_start?(call)

      call.update!(started_at: twilio_call.start_time, duration_seconds: call.duration_seconds || twilio_call.duration&.to_i)
      # Clients showing the call get the times, as with a status change
      call.message&.touch # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def apply(call, status, payload)
    Voice::StatusUpdateService.new(account: call.account, call_sid: call.provider_call_id, call_status: status, payload: payload).perform
  end

  # The times a callback would have carried: when the call was answered while it is live,
  # when it ended once over, and how long it lasted
  def timing(twilio_call)
    moment = twilio_call.end_time || twilio_call.start_time
    { 'Timestamp' => moment&.iso8601, 'CallDuration' => twilio_call.duration }.compact
  end
end
