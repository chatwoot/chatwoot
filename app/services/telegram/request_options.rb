# Every HTTParty call to the Bot API, with the two numbers this integration has and the
# reason each one is what it is.
#
# `max_retries: 0` on both: `Net::HTTP` repeats an idempotent request once by default, so
# a ceiling on a GET is worth half of what it reads as. Measured against a socket that
# accepts the connection and never answers, a GET at `timeout: 3` took 6.0s and 3.0s once
# the retry was closed.
#
# `timeout:` is a per-socket-operation ceiling and not a request deadline: it bounds how
# long one read may block, not how long the whole exchange may take. What sizes it is the
# far side's thinking time before the first byte comes back, which is why a send gets more
# than a status read and not the other way around.
module Telegram::RequestOptions
  # The calls whose answer the caller acts on right now, in the request the operator is
  # waiting on: validating the bot token and pointing the webhook at us, both inside the
  # inbox form, plus the two reads that resolve a file the contact just sent.
  TELEGRAM_SHORT_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze

  # Outbound. Telegram fetches the media from the URL we hand it before it answers, so
  # this one waits on Telegram waiting on us.
  #
  # A document does not come through here: it is uploaded byte by byte over Faraday, which
  # carries its own ceiling in `Telegram::SendAttachmentsService#multipart_post_connection`.
  TELEGRAM_REQUEST_OPTIONS = { timeout: 90, max_retries: 0 }.freeze
end
