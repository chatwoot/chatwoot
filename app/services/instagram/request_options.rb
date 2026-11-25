# Every HTTParty call to Instagram, with the two numbers this integration has and the
# reason each one is what it is.
#
# `max_retries: 0` on both: `Net::HTTP` repeats an idempotent request once by default, so
# a ceiling on a GET is worth half of what it reads as, and six of these eight are GETs.
#
# `timeout:` is a per-socket-operation ceiling and not a request deadline: it bounds how
# long one read may block, not how long the whole exchange may take. What sizes it is the
# far side's thinking time before the first byte comes back.
module Instagram::RequestOptions
  # Reading a story or a profile while an incoming message is being built, exchanging and
  # refreshing a token, and telling Instagram which events to send us. None of these has
  # a body for the far side to go fetch: they answer out of Instagram's own state.
  INSTAGRAM_SHORT_REQUEST_OPTIONS = { timeout: 10, max_retries: 0 }.freeze

  # Outbound. An attachment travels as a URL that Instagram fetches from us before it
  # answers, so this one waits on Instagram waiting on us.
  INSTAGRAM_REQUEST_OPTIONS = { timeout: 90, max_retries: 0 }.freeze
end
