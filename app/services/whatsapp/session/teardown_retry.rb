# Sends again a teardown the connector says it never attempted.
#
# `session.delete` and `session.logout` are published, not called: nothing waits for them,
# and their failures come back later as `command.failed` on the event stream. One answer
# there is a promise rather than a failure. `not_attempted` is the connector certain that
# nothing reached WhatsApp -- the socket was being dialled and the unlink was never called
# -- so the device is still linked on somebody's phone, and the contract tells a client to
# send the same command again. Treated as final it stays linked for good, because the
# credentials that would sign the unlink are the ones a later teardown throws away.
#
# Only that answer. `retryable?` says a retry might answer differently, which is true of
# the whole ProviderUnavailable family and says nothing about whether a teardown is still
# owed: `session_not_found` is retryable by that definition and means the teardown is
# already done.
#
# The answer usually arrives for a session no inbox holds any more (the inbox was
# destroyed or moved to another provider), which is why the consumer hands it here before
# dropping it as an orphan. The one inbox that can still be around is one an operator
# disconnected, and for that one what counts is the request, not the connection record:
# the backend notes the teardown when it sends it and withdraws the note when it is asked
# to connect, while `close` is also what any dropped connection writes and `open` is what
# a redial the teardown was racing writes.
module Whatsapp::Session::TeardownRetry
  TYPES = %w[session.logout session.delete].freeze

  # The same spacing as the LogoutJob, for the same reason: a socket being dialled is
  # usually back within seconds, and one that is not is down for a while.
  WAITS = [30.seconds, 2.minutes, 5.minutes, 15.minutes, 1.hour].freeze

  # How long the count of attempts outlives the last one. Longer than the widest wait, so
  # the count is still there when that attempt's answer comes back, and short enough that
  # a teardown asked for again another day starts over.
  ATTEMPTS_TTL = 2.hours

  # How long the note that a live inbox asked for a teardown lasts when nobody asks to
  # connect it. Not tied to the attempts: a teardown carries no deadline and can sit
  # pending for as long as the connector is away, and the answer that finally comes back
  # must still find the request standing. Only a connect withdraws it; the expiry is there
  # so the note of an inbox destroyed later does not stay forever.
  REQUEST_TTL = 7.days

  class << self
    def teardown?(payload)
      TYPES.include?(payload.command_type)
    end

    # Schedules the teardown again when the failure is the one the contract says to retry.
    # Answers whether it did.
    def consider(event)
      payload = event.payload
      return false unless teardown?(payload) && not_attempted?(payload.error)

      key = attempts_key(event.sid, payload.command_type)
      attempt = Redis::Alfred.get(key).to_i + 1
      wait = WAITS[attempt - 1]
      return give_up(event.sid, payload.command_type) if wait.nil?

      announce(event.sid, payload.command_type, wait, attempt)
      Whatsapp::Session::TeardownRetryJob.set(wait: wait).perform_later(event.sid, payload.command_type)
      # Counted once the retry is queued, never before. The consumer runs the event again
      # when the enqueue raises, and a count taken first would spend the budget on
      # attempts that never went out. A count that fails after the enqueue costs one extra
      # teardown, which asks for nothing new.
      count_attempt(key)
      true
    end

    # Noted by the backend when it sends a teardown, withdrawn when it is asked to connect.
    # Both run where the caller rescues the session errors and nothing else (the disconnect
    # endpoint answers ProviderUnavailable with a 503), so a Redis that is down arrives as
    # one of those, as it does from the connector client.
    #
    # Each also starts the attempts over. A teardown asked for again is a new one, and a
    # budget a previous one spent would give up on its first answer.
    def requested(session_id)
      translating_outages do
        forget_attempts(session_id)
        Redis::Alfred.setex(requested_key(session_id), '1', REQUEST_TTL)
      end
    end

    def withdrawn(session_id)
      translating_outages do
        forget_attempts(session_id)
        Redis::Alfred.delete(requested_key(session_id))
      end
    end

    # Whether the teardown is still what somebody wants. A session no inbox holds is
    # always owed one. An inbox that is still here is owed one only while nobody has asked
    # to connect it since the teardown was sent. A check, not a fence, like the LogoutJob's:
    # a connect that lands while the job is inside `send_again` is still ended by it.
    def wanted?(session_id)
      channel = Channel::Whatsapp.where(provider: 'native').where("provider_config->>'session_id' = ?", session_id).first
      return true if channel.nil?

      Redis::Alfred.exists?(requested_key(session_id))
    end

    # By the route the first one took: the logout on the session's own stream, where its
    # owner reads it at once, and the delete on the control stream, which reaches a session
    # nobody is running. Bounded by runtime alone, as the backend bounds them, because a
    # deadline would refuse a teardown that arrives while the session is between owners.
    def send_again(session_id, command_type)
      client = Whatsapp::Connector::Client.new(session_id)
      commands = Whatsapp::Session::Model::Commands
      runtime = Whatsapp::Session::Backends::Connector::Backend::TEARDOWN_RUNTIME
      id = case command_type
           when 'session.logout' then client.publish(commands::SessionLogout.new, max_runtime: runtime)
           when 'session.delete' then client.control(commands::SessionDelete.new, max_runtime: runtime)
           end
      Rails.logger.info("[WHATSAPP SESSION] #{command_type} sent again for session #{session_id}: #{id}")
    end

    def attempts_key(session_id, command_type)
      "WHATSAPP::SESSION::TEARDOWN_ATTEMPTS::#{session_id}::#{command_type}"
    end

    def requested_key(session_id)
      "WHATSAPP::SESSION::TEARDOWN_REQUESTED::#{session_id}"
    end

    private

    # Asked of the catalogue, so the code only counts once it maps to its class: a code
    # that degraded to Internal would not be sent again, which is what the catalogue spec
    # exists to catch.
    def not_attempted?(error)
      error.present? && error.to_exception.is_a?(Whatsapp::Session::Errors::NotAttempted)
    end

    def forget_attempts(session_id)
      TYPES.each { |command_type| Redis::Alfred.delete(attempts_key(session_id, command_type)) }
    end

    def translating_outages
      yield
    rescue Redis::BaseError, ConnectionPool::TimeoutError => e
      raise Whatsapp::Session::Errors::ProviderUnavailable, "the teardown record could not be written: #{e.class}: #{e.message}"
    end

    def announce(session_id, command_type, wait, attempt)
      Rails.logger.info(
        "[WHATSAPP SESSION] #{command_type} for session #{session_id} was not attempted by the connector; " \
        "sending it again in #{wait.inspect} (attempt #{attempt} of #{WAITS.size})"
      )
    end

    def count_attempt(key)
      Redis::Alfred.incr(key)
      Redis::Alfred.expire(key, ATTEMPTS_TTL.to_i)
    end

    def give_up(session_id, command_type)
      Rails.logger.warn(
        "[WHATSAPP SESSION] #{command_type} for session #{session_id} was not attempted #{WAITS.size + 1} times; " \
        'giving up, and the device may still be linked on the phone that paired it'
      )
      false
    end
  end
end
