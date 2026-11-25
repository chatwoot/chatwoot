# Periodic health read for a session inbox whose provider has to be asked.
#
# Two things only a poll can learn: that the session died without the provider saying so
# (a hosted instance can be disconnected from its own dashboard, or simply stop), and the
# account limits, which are never pushed. Both are read, never re-connected: re-arming a
# session that is up is the connector's job on its own side, and asking a hosted provider
# to connect every five minutes would re-register the webhook for nothing.
class Whatsapp::Session::ConnectionCheckJob < ApplicationJob
  queue_as :low

  def perform(channel)
    return unless channel.session_provider?

    backend = channel.session_backend
    return unless backend.class.state_polling?

    # Both writes are fenced to the instance this backend was built for. A conversion, or a
    # re-pointing to another instance of the same provider, can land while a request is in
    # flight: the first would write into the empty connection record the new provider just
    # started with, and the second would report one instance's state, down to a phone
    # number that reads as the wrong one and ends the new session, under another.
    fence = { provider: channel.provider, instance: Whatsapp::Session::Registry.instance_fingerprint(channel) }
    refresh_state(channel, backend, fence)
    refresh_limits(channel, backend, fence)
  end

  private

  def refresh_state(channel, backend, fence)
    Whatsapp::Session::ConnectionStateWriter.new(channel).apply(backend.fetch_connection_state, **fence)
  rescue Whatsapp::Session::Errors::Error => e
    # A provider that cannot be reached is not the same as a session that closed, and
    # writing `close` over a healthy connection because of one failed request would show
    # the operator an outage that is not there. The next cycle asks again.
    Rails.logger.warn("[WHATSAPP SESSION] connection check failed for inbox ##{channel.inbox&.id}: #{e.message}")
  end

  # Best effort, and separately rescued: a provider that answers the status but not the
  # limits must not cost the status read. A missing value means "unknown" and leaves the
  # last one in place, so a blip never clears a banner that is legitimately up.
  #
  # The fence is inside the lock, which is the only place it means anything: these are
  # sticky fields, so a limit written onto an inbox that has just been converted survives
  # every state update the new provider sends and shows the agent the old provider's
  # restrictions until the new one happens to report its own.
  def refresh_limits(channel, backend, fence)
    # A backend that does not declare the limits refuses them, and the refusal would be
    # logged as a failed read on every cycle: a provider saying it has nothing to report
    # is not a provider failing to report.
    return unless backend.supports?('account_limits')

    limits = backend.fetch_account_limits || {}
    channel.with_lock do
      next if channel.provider != fence[:provider]
      next if fence[:instance] != Whatsapp::Session::Registry.instance_fingerprint(channel)

      channel.update_account_limits!(limits)
    end
  rescue Whatsapp::Session::Errors::Error => e
    Rails.logger.warn("[WHATSAPP SESSION] account limits refresh failed for inbox ##{channel.inbox&.id}: #{e.message}")
  end
end
