# Ceilings for the Z-API provider. Z-API publishes no deadline of its own, so unlike the Baileys
# ones these numbers come from this side, and saying so is part of them: what is measured here is
# what a stall costs us, not what the far side promises.
#
# What a `timeout:` actually bounds is one socket operation, not the request. Measured against a
# server that answers one byte every 300ms with `read_timeout = 1`: the request completed in 11.8
# seconds. So a ceiling does not cap how long a send takes; it caps how long the socket may sit
# still. That is why the size of a body does not decide the number, and why the think time of the
# far side does.
#
# `max_retries: 0` on both. `Net::HTTP` retries GET, HEAD, PUT, DELETE, OPTIONS and TRACE once by
# default, so half of this provider's calls silently cost twice their ceiling, and a repeated
# DELETE of a message or PUT of the webhook set is a second effect nobody asked for.
module Whatsapp::ZapiRequestOptions
  # Control and reads: connection status, webhook setup, disconnect, QR code, read receipts,
  # phone-exists, message delete. Small bodies, and Z-API answers them out of its own state, so
  # ten seconds of silence is already a wedged socket rather than a slow answer.
  ZAPI_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze

  # Sends. The long wait here is not the upload -- that is many writes, each bounded by this same
  # number -- it is the single blocked read while Z-API forwards the message to WhatsApp and only
  # then answers. Media travels base64 inside the body (up to 5 MB for an image, 16 for audio and
  # video, 100 for a document), so that forward can legitimately take tens of seconds. 90s is the
  # number the Baileys provider already uses for a media-bearing send, for the same reason; there
  # it is tied to a published 75s proxy cut, and here it is not tied to anything the far side
  # states, which is the honest difference between the two.
  ZAPI_SEND_OPTIONS = { timeout: 90, max_retries: 0 }.freeze
end
