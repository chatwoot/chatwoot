# Two ceilings for the Baileys API, and the numbers come from the API's own, not from taste.
#
# Measured on `fazer-ai/baileys-api` at `112d95e`:
#
#   PROXY_REQUEST_TIMEOUT_MS  75_000   the API's proxy cuts every request at this
#   defaultQueryTimeoutMs     60_000   how long Baileys itself waits on an IQ to WhatsApp
#   BAILEYS_SEND_TIMEOUT_MS   45_000   the send's own deadline, plus a 20s audio budget
#
# Almost every route awaits a socket call, so 60s is a legitimate duration there, and the
# proxy answers for itself at 75s. A ceiling below that is a ceiling that can hang up on a
# provider that was about to answer, and for a write that means we report a failure for
# something that happened. 90s is therefore the default: above the proxy's cut, so what we
# get back is the API's structured 503/504 rather than a bare `Net::ReadTimeout`, and never
# reached in practice because the far side always answers first. It is the number
# `send_message_request` already chose, for these same reasons, written down once.
#
# `max_retries: 0` is on both, and it is the half that a `timeout:` alone does not buy.
# `Net::HTTP` retries an idempotent request once by default, so a GET costs twice its
# ceiling and a POST costs it once. Measured against a socket that accepts the connection
# and never answers:
#
#   GET  timeout: 5                    10.0s
#   GET  timeout: 5, max_retries: 0     5.0s
#   POST timeout: 5                     5.0s
#
# Nothing here is safe to replay at the transport layer anyway: the send carries the API's
# idempotency key and every other call is a command, so a silent second attempt is a second
# effect nobody asked for.
module Whatsapp::BaileysRequestOptions
  BAILEYS_REQUEST_OPTIONS = { timeout: 90, max_retries: 0 }.freeze

  # The calls that deliberately give up before the provider does. Every one is a read whose
  # caller already treats silence as "I do not know" and changes nothing: `get_profile_pic`,
  # `fetch_reachout_timelock`, `fetch_send_health` and `fetch_new_chat_cap` answer nil, and
  # `presence_subscribe` is rescued and logged by Conversations::PresenceSubscribeService. For
  # those, waiting out a wedged socket buys an answer nobody is going to act on.
  #
  # Two calls used to sit here and no longer do. `import_session` and
  # `disconnect_channel_provider` have callers that act on the outcome, and between 10s and the
  # provider's own 75s cut they were giving up on an operation still in progress: the disconnect
  # left `provider_connection` untouched, so an inbox whose session had in fact ended stayed
  # recorded as open with nothing to correct it later, and the import answered the operator
  # "try again" for an import that may have completed (fazer-ai/chatwoot#600).
  BAILEYS_SHORT_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze

  # A lookup a web request waits on: the number check that starts a conversation. rack-timeout
  # cuts that request at RACK_TIMEOUT_SERVICE_TIMEOUT (15 s unless an installation sets it) with a
  # Thread#raise nothing downstream can rescue, and the full 90 s turned a wedged socket into a
  # 500 with no conversation created (fazer-ai/chatwoot#880). Three quarters of the cut leaves the
  # rest of the request room to answer and treat silence as "unknown"; never more than the full
  # ceiling. Measured on one installation with a 60 s cut, the slowest real answer took 18.5 s,
  # under the 45 s this gives there.
  def self.in_request_timeout(rack_timeout)
    seconds = rack_timeout.to_f
    seconds = 15.0 unless seconds.positive?
    [(seconds * 0.75).floor, BAILEYS_REQUEST_OPTIONS[:timeout]].min
  end

  BAILEYS_IN_REQUEST_OPTIONS = { timeout: in_request_timeout(ENV.fetch('RACK_TIMEOUT_SERVICE_TIMEOUT', nil)), max_retries: 0 }.freeze
end
