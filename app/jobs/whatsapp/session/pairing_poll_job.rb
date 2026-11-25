# Drives the pairing screen for backends that have to be polled.
#
# A QR rotates about every 20 seconds and the provider's webhook is not guaranteed to
# push every rotation, so the operator would be left staring at a code that stopped
# working. This job pulls the state until the session opens, the pairing is abandoned,
# or the ceiling below is reached.
class Whatsapp::Session::PairingPollJob < ApplicationJob
  queue_as :high

  INTERVAL = 15.seconds
  # A QR expires far sooner than a pairing code, which the operator has to type on the
  # phone. A resume has neither in front of it: nothing on screen is going stale and the
  # provider is bringing an existing pairing back up, which takes as long as the network
  # makes it take, so it gets the longer of the two. All three are ceilings on the whole
  # attempt, not on a single code.
  DEADLINES = { 'qr' => 2.minutes, 'code' => 5.minutes, 'resume' => 5.minutes }.freeze

  # What the operator reads when the ceiling is reached. A resume never showed a code, so
  # reporting an expired one sends them looking for a screen that was never there: what
  # happened is that the session did not come back, and the provider keeps trying on its
  # own.
  TIMEOUT_ERRORS = { 'resume' => 'connect_failure' }.freeze

  # Resolved by whoever starts the attempt, so the ceiling covers the queue wait too.
  def self.deadline_for(pairing)
    Time.current + DEADLINES.fetch(pairing.to_s, DEADLINES['qr'])
  end

  # `pairing` is the mode the connect command asked for; `deadline_at` is set on the first
  # run and carried forward so re-enqueueing never extends the ceiling.
  #
  # `fence` is which pairing this chain belongs to: its provider, the instance behind it
  # and the attempt that claimed the screen. An inbox converted, re-pointed at another
  # instance, or connected again while a poll sat in the queue would otherwise be polled
  # against whatever it became, and this chain's timeout would land on somebody else's
  # live QR. A chain runs for minutes, so the window is not a small one.
  def perform(channel, pairing: 'qr', deadline_at: nil, fence: {})
    @channel = channel
    @pairing = pairing.to_s
    @fence = (fence || {}).symbolize_keys
    @deadline_at = deadline_at || self.class.deadline_for(@pairing)
    return unless current?

    backend = channel.session_backend
    poll(backend) if backend.class.state_polling?
  rescue Whatsapp::Session::Errors::Error => e
    # The instance being unreachable mid-pairing is the operator's problem to see on the
    # screen, not something a retry storm fixes: the next connect starts a fresh poll.
    Rails.logger.warn("[WHATSAPP SESSION] pairing poll failed for ##{channel.id}: #{e.message}")
    give_up('connect_failure')
  end

  private

  attr_reader :channel, :pairing, :fence, :deadline_at

  def provider = fence[:provider]
  def instance = fence[:instance]
  def attempt = fence[:attempt]

  # Whether the inbox is still the one this chain started on, and still on this attempt.
  # Re-read every time, including after the provider request, because a conversion or a
  # second connect can land while this job is waiting on the network.
  def current?
    channel.reload
    return false if provider.present? && channel.provider != provider
    return false if instance.present? && instance != Whatsapp::Session::Registry.instance_fingerprint(channel)
    return true if attempt.blank?

    channel.provider_connection['pairing_attempt'] == attempt
  end

  def poll(backend)
    state = backend.fetch_connection_state
    return unless current?

    # Fenced, not merely checked above: a second connect claiming the pairing between that
    # check and this write would have its QR replaced by the one this chain is holding,
    # and the chain driving the screen would retire itself over a token it never wrote.
    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(state.with_attempt(attempt), attempt: attempt,
                                                                                             instance: instance)
    return if settled?(state)
    return give_up(TIMEOUT_ERRORS.fetch(pairing, 'pairing_timed_out')) if Time.current + INTERVAL >= deadline_at

    self.class.set(wait: INTERVAL).perform_later(
      channel, pairing: pairing, deadline_at: deadline_at, fence: fence
    )
  end

  # Both ways a pairing ends without succeeding write the reason to the connection record.
  # Leaving the last `connecting` state in place parks the dashboard on a QR that expired
  # minutes ago, waiting for a rotation that is never coming.
  def give_up(error)
    return unless current?

    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(
      Whatsapp::Session::Model::ConnectionState.new(connection: 'close', error: error), attempt: attempt,
                                                                                        instance: instance
    )
  end

  # Anything that is not still trying to connect ends the poll: `open` means paired, and
  # a closed connection means the attempt was abandoned or refused. `reconnecting` is
  # the provider still working on it, which is exactly when the poll is needed: the QR
  # keeps rotating and the push that would carry it is the thing this job exists to
  # replace, so treating it as settled leaves the operator on a dead code.
  def settled?(state)
    !state.connecting?
  end
end
