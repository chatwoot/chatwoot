# What to raise when a send never got an answer at all.
#
# A response that comes back, whatever it says, is something the caller can classify: a 400 is a
# refusal, a 503 is the provider saying it is down. This is the other case, where there is no
# response to look at -- the socket timed out, the connection was reset, the handshake failed --
# and the send escapes as whatever the HTTP stack raised. That class is not in the session error
# hierarchy, so `SendReplyJob`'s `retry_on` never matched it: the block that marks the message
# failed did not run, the exception reached Sidekiq, and its three retries sent the message again
# each time, with nothing on the agent's screen to say so (fazer-ai/chatwoot#605).
#
# Rescued as a CLASS rather than as a list of exception types, which is why the caller must wrap
# nothing but the HTTP call in it: an enumerated list is a promise to have thought of every way a
# socket can fail, and it will be wrong (Net::WriteTimeout on a large media body,
# OpenSSL::SSL::SSLError on a handshake, whatever the next TLS or HTTP gem raises). Anything
# StandardError can be at that one line is a transport failure by construction.
#
# The shape is the Baileys provider's `post_send_message`, which has had it since #391. This is
# that reasoning made shareable, so the three providers that still lacked it answer the same way.
module Whatsapp::TransportFailure
  # Failures that cannot have put a single byte of the request on the wire. Everything else
  # defaults to indeterminate, and the asymmetry is deliberate: calling a possibly-delivered send
  # "the provider is unreachable" makes it retryable, and a retry of a send that did arrive is a
  # second copy in front of the customer. Calling a never-sent one indeterminate costs the agent
  # one click to resend.
  NEVER_TRANSMITTED = [
    Net::OpenTimeout, SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH
  ].freeze

  OUTGOING_ERRORS_SCOPE = 'errors.inboxes.channel.outgoing'.freeze

  private

  def raise_transport_failure(error)
    Rails.logger.error("[WHATSAPP] transport failure on send: #{error.class}: #{error.message}")

    raise Whatsapp::Session::Errors::ProviderUnavailable, unreachable_message if never_transmitted?(error)

    raise Whatsapp::Session::Errors::SendOutcomeUnknown, unknown_outcome_message
  end

  def never_transmitted?(error)
    NEVER_TRANSMITTED.any? { |klass| error.is_a?(klass) }
  end

  # Resolved at raise time rather than in a constant: I18n.locale is per request, and a constant
  # would freeze whichever locale booted the process. This sentence reaches the agent as the
  # message's `external_error`.
  def unreachable_message = I18n.t("#{OUTGOING_ERRORS_SCOPE}.provider_unreachable")
  def unknown_outcome_message = I18n.t("#{OUTGOING_ERRORS_SCOPE}.send_outcome_unknown")
end
