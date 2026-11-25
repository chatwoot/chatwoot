# One clock for every Graph call a request makes.
#
# `Whatsapp::GraphRequestOptions` gives each call a ceiling, and a ceiling per call composes with the
# number of calls: `register_webhook` makes four, so four answers that each arrive just under the ceiling
# hold the request for four ceilings (fazer-ai/chatwoot#592). A deadline is the other axis. Each call still
# carries its own ceiling, cut to what is left of the request, and a call that would not have time to open
# a connection is not made at all.
#
# Two limits worth saying, so nobody sizes this by the wrong one. The ceiling HTTParty applies is per socket
# operation, so a server that answers one byte at a time can outlast it, and it can outlast this too. And
# the deadline is created per request and handed down explicitly: a request that ran out of time must not
# leave the next request on the same thread starting out of time.
class Whatsapp::GraphDeadline
  class Exceeded < StandardError; end

  # Below this, a TLS handshake to Meta alone may not finish, so a call made anyway is a failure spent on
  # the network instead of one decided here.
  MINIMUM_CALL_SECONDS = 1

  def self.in(seconds)
    new(now + seconds)
  end

  def self.now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def initialize(expires_at)
    @expires_at = expires_at
  end

  # The timeout to splat after the options a call already carries, so the later key wins:
  #
  #   get(url, **GRAPH_REQUEST_OPTIONS, **@deadline.cut(GRAPH_REQUEST_OPTIONS))
  #
  # The constant stays written at the call on purpose. The ceiling fences resolve a call's axes from the
  # constant it splats (`spec/lib/request_ceilings_spec.rb`, `graph_request_options_spec.rb`), and a call
  # whose options came back from a method would read to them as a call with no ceiling at all.
  def cut(options)
    left = @expires_at - self.class.now
    raise Exceeded, "no time left for another Graph call (#{left.round(2)}s of the request's deadline)" if left < MINIMUM_CALL_SECONDS

    { timeout: [options[:timeout], left].min }
  end

  # For every caller that has no request to answer inside: never out of time, so the per-call ceiling stands.
  NONE = new(Float::INFINITY).freeze
end
