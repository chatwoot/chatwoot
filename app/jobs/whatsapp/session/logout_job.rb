# Drops a session Chatwoot refuses to keep, retrying until the provider takes the order.
#
# The one caller is the wrong-number rejection, where a swallowed failure is the worst
# outcome available: the state is already written, so the handler will report every
# repeat of it as unchanged and never reach the logout again, and the wrong WhatsApp
# account stays connected with nobody asking it to stop.
#
# Taking the order is not the same as carrying it out. The native provider publishes the
# logout and answers a failure later, on the event stream, and the first logout of a wrong
# account lands right after the pairing, while the session is swapping sockets and refuses
# it. So the logout is sent again, further apart each time, until the account is reported
# unlinked or the quarantine is gone. Only where a logout actually unpairs: a provider
# whose logout is a disconnect never reports the account gone, and repeating it would only
# disconnect the same account again.
class Whatsapp::Session::LogoutJob < ApplicationJob
  queue_as :high

  retry_on Whatsapp::Session::Errors::ProviderUnavailable, wait: :polynomially_longer, attempts: 6
  retry_on Whatsapp::Session::Errors::RateLimited, wait: :polynomially_longer, attempts: 6

  # How long each logout gets to be reported before the next one goes. The first is short,
  # because the reconnect that refused the first logout is over in seconds; the rest spread
  # out for a session that is down for longer, and stop inside a couple of hours.
  WAITS = [30.seconds, 2.minutes, 5.minutes, 15.minutes, 1.hour].freeze

  def perform(channel, attempt: 1)
    # Re-read, because a retry of this job can run minutes after the rejection that
    # queued it: the administrator may have corrected the number and paired again, or
    # converted the inbox altogether, and logging out then kills the session that
    # replaced the one this was sent to remove. The quarantine is the whole reason this
    # job exists, so its absence is reason enough not to run.
    #
    # A check, not a fence, and it cannot be one here: a retry that passes it and is still
    # inside the provider call when the operator reconnects ends the new session anyway.
    # Closing that needs a logout naming the session it means to end, and `session.logout`
    # addresses whichever session the inbox holds now. The operator's own sequence does
    # not depend on it: `Facade#setup_channel_provider` ends the wrong account inline
    # before connecting, and this job then finds no quarantine and stands down.
    return unless Whatsapp::Session::ConnectionStateWriter.disowned?(channel.reload)
    return if Whatsapp::Session::ConnectionStateWriter.unlinked?(channel)
    return give_up(channel) if attempt > WAITS.size

    backend = channel.session_backend
    backend.logout
    self.class.set(wait: WAITS[attempt - 1]).perform_later(channel, attempt: attempt + 1) if backend.class.unpairs?
  rescue Whatsapp::Session::Errors::ProviderUnavailable, Whatsapp::Session::Errors::RateLimited
    raise
  rescue Whatsapp::Session::Errors::Error => e
    # Nothing a retry fixes: the session is already gone, or the backend cannot be asked.
    Rails.logger.warn("[WHATSAPP SESSION] logout failed for inbox #{channel.inbox&.id}: #{e.message}")
  end

  private

  # Nothing reported the account unlinked after every logout had its wait, so it may still
  # be listed on the phone that scanned the code. Said out loud, because the quarantine
  # keeps its chats out and nothing else on the inbox would show it.
  def give_up(channel)
    Rails.logger.warn(
      "[WHATSAPP SESSION] #{WAITS.size} logouts sent for inbox #{channel.inbox&.id} and none reported the wrong account unlinked; " \
      'it may still be linked on the phone that scanned the code'
    )
  end
end
