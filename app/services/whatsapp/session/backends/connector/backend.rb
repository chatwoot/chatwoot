# The `native` provider: a session held by the Go connector, reached over Redis.
#
# Every method here is the same shape: build a canonical command, hand it to the client,
# and turn the reply into the canonical object the caller expects. What is fire and
# forget on the wire is fire and forget here too, and its failures come back later as a
# command.failed event rather than as a return value.
class Whatsapp::Session::Backends::Connector::Backend < Whatsapp::Session::Backend
  # A cap on what a single media download may pull into the Rails process. WhatsApp
  # itself stops well below this; the limit is there so a wrong URL cannot fill a disk.
  MAX_MEDIA_BYTES = 100.megabytes

  # How fast a file is assumed to move, end to end, when sizing the wait for a send that
  # carries one. Deliberately pessimistic: the connector has to fetch the file from this
  # app's storage, encrypt it into a temporary file and upload it to WhatsApp before it
  # can answer, and the number that matters is the slowest of those links rather than the
  # one inside the datacentre.
  MEDIA_SEND_RATE = ENV.fetch('WHATSAPP_MEDIA_SEND_RATE_BYTES', 1.megabyte).to_i

  # The ceiling on that wait. A send holds a Redis connection out of the pool and the
  # worker that called it for as long as it runs, so a file too big to move inside this
  # is one this deployment does not send -- and it says so on the deadline rather than by
  # holding a worker indefinitely.
  MEDIA_SEND_MAX_TIMEOUT = ENV.fetch('WHATSAPP_MEDIA_SEND_MAX_TIMEOUT', 180).to_i

  # Seconds between the attempts at a group creation the connector answered `not_settled`.
  # Four attempts over three and a half seconds: the notification that settles one
  # ordinarily arrives within seconds, and the creation runs inside an HTTP request.
  NOT_SETTLED_WAITS = [0.5, 1, 2].freeze

  # --- the ceiling on a published command ------------------------------------------
  #
  # A published command carries no `reply_to`, so nobody here is waiting to give up on it
  # and whatever ceiling the frame declares is the only limit the connector has. The
  # session's executor takes one command at a time, so a published command with no ceiling
  # at all, parked on a socket write, is every send behind it parked too.
  #
  # The frame offers two, and which one a command wants follows from what a late execution
  # would cost it. `deadline` is an instant, refusing the command unrun once it passes, so
  # it is for the commands that are wrong rather than merely late when they land. The
  # runtime ceiling below is counted from the moment the work starts and can never drop
  # anything, so it is for the ones that have to happen whenever they arrive.
  #
  # The timeouts here are deadlines. The teardown takes the other one, on its own constant.

  # A momentary state that lands late is not late, it is wrong: an `available` applied
  # after the agent went offline flips the account back, and a `composing` applied minutes
  # later is a typing bubble for something nobody is typing.
  MOMENTARY_TIMEOUT = 30

  # Under the 15 s a request may run: see `check_numbers`.
  NUMBER_CHECK_TIMEOUT = 5

  # These are still right whenever they land, so the only reason to bound them is the
  # executor, and the ceiling has to clear the longest command that can legitimately be
  # ahead of them on the same queue: a send carrying a file. A queue holding several of
  # those back to back can still expire one, and what that costs is a receipt the
  # customer's phone never shows, repaired the next time the same chat is read.
  DEFERRABLE_TIMEOUT = MEDIA_SEND_MAX_TIMEOUT + Whatsapp::Connector::Client::RPC_TIMEOUT

  # A pairing code is worth as long as the attempt that asked for it, which is the ceiling
  # the pairing screen already runs on: past it, the screen the operator would type the
  # code into is gone.
  PAIRING_TIMEOUT = Whatsapp::Session::PairingPollJob::DEADLINES.fetch('code').to_i

  # The teardown takes the other ceiling, the one counted from when the work starts, and
  # takes it alone. A deadline would be the wrong half: a teardown is deliberately left
  # pending while the session is between owners, and refusing it for arriving late leaves
  # a device listed on the customer's phone with nothing here corresponding to it. What
  # the runtime ceiling bounds instead is a teardown parked on a socket write, and it
  # cannot drop anything, because the clock only starts once the connector picks it up.
  #
  # Generous, because the wait it exists to end is a half-open socket rather than a slow
  # answer: WhatsApp answers an unlink in well under a second, and a socket that is simply
  # down answers at once with a refusal. Everything the connector still owes itself after
  # the unlink runs outside this ceiling, by contract.
  TEARDOWN_RUNTIME = 30

  class << self
    def provider_key
      'native'
    end

    def capabilities
      Whatsapp::Session::Registry.descriptor('native').capabilities
    end

    # `session.logout` unregisters the device with WhatsApp: the store's credentials go
    # with it, and the next connect asks for a new QR.
    def unpairs?
      true
    end

    # The connector files what arrived while the session was down in the same dump as the
    # archive, and publishes neither without being asked at connect.
    def history_on_every_connect?
      true
    end

    def history_needs_anchor?
      true
    end

    PROXY_SCHEMES = %w[http https socks5].freeze

    # The session id is generated when the inbox is saved and the toggles are optional, so
    # nothing can be missing here. What can be wrong is the proxy: the connector takes
    # http, https or socks5 with a host and refuses anything else with `invalid_payload`,
    # which is better said while the operator is still on the form than on the connect.
    def validate_config(provider_config)
      url = provider_config['proxy_url'].to_s
      return [] if url.blank?

      uri = URI.parse(url)
      PROXY_SCHEMES.include?(uri.scheme) && uri.host.present? ? [] : ['proxy_url']
    rescue URI::InvalidURIError
      ['proxy_url']
    end
  end

  # Resolved when they are called, never held in a constant: a constant captured at load
  # time keeps the namespace from before the last reload, and its autoloaded children are
  # gone from it by then.
  def model = Whatsapp::Session::Model
  def commands = Whatsapp::Session::Model::Commands

  def client
    @client ||= Whatsapp::Connector::Client.new(session_id)
  end

  # --- session lifecycle ---------------------------------------------------------

  def connect(command)
    # Nobody owns a session that has never paired, so nobody is reading its command
    # stream and a connect written straight to it would sit there until its deadline.
    # The wake goes on the control stream, which every instance reads, and asks whichever
    # answers to take the session before the connect lands on it.
    #
    # Asking to connect withdraws any teardown still owed to this session, so a retry of
    # one the connector never attempted does not end the session being set up now.
    Whatsapp::Session::TeardownRetry.withdrawn(session_id)
    client.control(commands::SessionWake.new(desired: 'connected'))
    model::ConnectionState.from_h(client.call(command))
  end

  def disconnect
    client.publish(commands::SessionDisconnect.new, max_runtime: TEARDOWN_RUNTIME)
  end

  # The operator's Disconnect since it stopped deleting the session (fazer-ai/chatwoot#852),
  # so it reaches the places the teardown below does, by the same means. A connector reads
  # `wa:cmd:<sid>` only while it runs the session, and a session nobody owns -- handed back,
  # or waiting out a resume backoff -- would leave the logout there undelivered: the wake, on
  # the control stream, has some instance adopt it, and `disconnected` has it stop there
  # instead of dialling. And the note is what lets a logout the connector never attempted be
  # sent again while the inbox still exists; connecting withdraws it, as it does a teardown.
  def logout
    Whatsapp::Session::TeardownRetry.requested(session_id)
    client.control(commands::SessionWake.new(desired: 'disconnected'))
    client.publish(commands::SessionLogout.new, max_runtime: TEARDOWN_RUNTIME)
  end

  # The teardown, and the two halves go by different routes because they cover states the
  # other cannot reach.
  #
  # `session.delete` goes on the **control stream**, which every connector instance reads.
  # A connector reads `wa:cmd:<sid>` only for the sessions it is running, so a teardown
  # written there for an account nobody has adopted is delivered to nobody at all and dies
  # when the stream is trimmed -- and that is exactly the state a teardown is most often
  # sent in: an inbox destroyed while its session was down, or destroyed while the
  # connector fleet was restarting. On the control stream, whoever reads it adopts the
  # account for the length of the teardown and tears it down without ever connecting.
  #
  # The `session.logout` stays, on the session's own stream, and it is not redundant.
  # Delivery through the control stream is to *some* instance rather than to the one
  # running the account: an entry naming a session somebody else owns is left pending and
  # reclaimed until it reaches that owner, which happens but is not bounded. The logout
  # rides the owner's own stream, so for a session that is up the device is unlinked at
  # once, and the delete that follows finds nothing linked, which is a teardown with less
  # to do rather than a failure. It is also what keeps this working against a connector
  # build older than fazer-ai/whatsapp-connector#157, whose `session.delete` has no
  # handler and answers `unsupported`.
  #
  # Neither is `call`ed. This runs inside the transaction that destroys the inbox, and an
  # RPC there would hold it open for the round trip. And a teardown is deliberately left
  # pending, with no reply at all, while the session is between owners -- being handed
  # over, or waiting on a lease with room to finish -- so a caller waiting for an answer
  # would time out exactly when the connector is doing the right thing.
  #
  # Logged here, which is the only place it can be. The connector answers a teardown it
  # could not carry out with `command.failed`, and that event is routed to an inbox by
  # `session_id`: the inbox this one is about has just been destroyed, so the lookup
  # misses. The consumer acts on one answer before dropping the orphan, a teardown the
  # connector never attempted, which Whatsapp::Session::TeardownRetry sends again; every
  # other failure is dropped, and what we publish is the last thing about this session
  # that anybody can see.
  #
  # The two ids go into the hash the log line carries. Ruby evaluates the values in the
  # order they are written, so the logout is still sent first, and a spec pins that
  # ordering rather than leaving it to be read out of this comment.
  def delete_session
    Whatsapp::Session::TeardownRetry.requested(session_id)
    asked = { logout: client.publish(commands::SessionLogout.new, max_runtime: TEARDOWN_RUNTIME),
              delete: client.control(commands::SessionDelete.new, max_runtime: TEARDOWN_RUNTIME) }
    Rails.logger.info("[WHATSAPP] tearing session #{session_id} down for inbox #{channel.inbox&.id}: #{asked.to_json}")
  end

  def fetch_connection_state
    model::ConnectionState.from_h(client.call(commands::SessionStatus.new))
  end

  # The code itself arrives as a pairing.code event: WhatsApp takes its time issuing it,
  # and the inbox screen is already listening for connection updates.
  def request_pairing_code(command)
    client.publish(command, timeout: PAIRING_TIMEOUT)
    nil
  end

  # --- messages ------------------------------------------------------------------

  def send_message(command)
    model::SendResult.from_h(
      client.call(command, idempotency_key: "msg:#{command.message_id}", timeout: send_timeout(command))
    )
  end

  # How long to wait for a send, which for a file is not the same question as for a text.
  #
  # Every other RPC answers in milliseconds and the default is right for them. A send with
  # a file has to cover three transfers before the connector can answer, and under the
  # default only a few megabytes fit: past that the send fails on the deadline, is
  # retried, and fails at the same place -- which is why the documented cap was never
  # reachable through this client.
  #
  # Sized from the length the sender already declared rather than from that cap, so a
  # small file is not given the budget meant for the largest one. Never shorter than the
  # default, because every other reason to wait is unchanged.
  def send_timeout(command)
    size = command.content.try(:size).to_i
    return Whatsapp::Connector::Client::RPC_TIMEOUT if size <= 0

    budget = Whatsapp::Connector::Client::RPC_TIMEOUT + (size.to_f / MEDIA_SEND_RATE).ceil
    budget.clamp(Whatsapp::Connector::Client::RPC_TIMEOUT, MEDIA_SEND_MAX_TIMEOUT)
  end

  def edit_message(command)
    model::SendResult.from_h(client.call(command, idempotency_key: "msg:#{command.message_id}"))
  end

  def revoke_message(command)
    client.call(command)
    true
  end

  def react_message(command)
    model::SendResult.from_h(client.call(command, idempotency_key: "msg:#{command.message_id}"))
  end

  # The answer is not this call's: the phone answers, when it is awake to, with
  # `history.sync` events typed `on_demand`. A call rather than a publish so a refusal
  # (a session that went down since the button was offered, an anchor the connector will
  # not take) reaches the job that asked instead of being logged by nobody.
  def request_history(command)
    client.call(command)
    nil
  end

  def mark_read(command)
    client.publish(command, timeout: DEFERRABLE_TIMEOUT)
  end

  def mark_unread(command)
    client.publish(command, timeout: DEFERRABLE_TIMEOUT)
  end

  # The connector keeps the bytes on its own disk and serves them over its internal HTTP
  # port; the ref that came with the event is a URL there. Those blobs are dropped on a
  # TTL and an LRU quota, so a ref that has lapsed, or one whose blob turns out to be gone
  # already, is asked for again: that makes the connector download it from WhatsApp anew.
  def download_media(command)
    ref = command.ref
    return fetch_blob(refresh(command)) if ref.nil? || !ref.fetchable?

    begin
      fetch_blob(ref)
    rescue Whatsapp::Session::Errors::MediaUnavailable, Whatsapp::Session::Errors::ProviderUnavailable
      # Dropped between the event and this job, which the quota makes ordinary rather than
      # exceptional, or served by an instance that is no longer there: a blob URL names
      # the instance that downloaded it, and that one can be replaced before the job runs.
      # Asking again reaches whoever holds the session now; if that copy is gone as well,
      # it is gone.
      fetch_blob(refresh(command))
    end
  end

  # --- presence and contacts -----------------------------------------------------

  def send_chat_presence(command)
    client.publish(command, timeout: MOMENTARY_TIMEOUT)
  end

  def update_presence(command)
    client.publish(command, timeout: MOMENTARY_TIMEOUT)
  end

  def subscribe_presence(command)
    client.publish(command, timeout: DEFERRABLE_TIMEOUT)
  end

  # Asked from inside a request, whose caller falls back to the typed number when the
  # check fails, so the check gives up long before the request does (#838). On the RPC
  # default it waited 20 s, past the request's own limit, and the fallback never ran. A
  # dial asks inside its own budget and says how much of it the check may have.
  def check_numbers(command, timeout: NUMBER_CHECK_TIMEOUT)
    Array(client.call(command, timeout: timeout)).map { |check| model::NumberCheck.from_h(check) }
  end

  def profile_picture_url(command)
    result = client.call(command)
    result.is_a?(Hash) ? result['url'] : result
  end

  def resolve_contact(command, timeout: Whatsapp::Connector::Client::RPC_TIMEOUT)
    model::Party.from_h(client.call(command, timeout: timeout))
  end

  # --- groups --------------------------------------------------------------------

  # The connector writes a group creation down before it asks WhatsApp, so a retry under
  # the same key collects the group the first attempt made, and a retry under a fresh key
  # makes a second one. `not_settled` says WhatsApp has not yet named which request made
  # which group, which ordinarily takes seconds. The contract also names the state asking
  # does not resolve, an intent recorded whose request never went out, so the waits are
  # bounded and what survives them is logged as stranded rather than retried further.
  def create_group(command)
    key = "group:#{SecureRandom.uuid}"
    waits = NOT_SETTLED_WAITS.dup
    begin
      model::GroupInfo.from_h(client.call(command, idempotency_key: key))
    rescue Whatsapp::Session::Errors::NotSettled
      wait = waits.shift
      if wait.nil?
        Rails.logger.error("[WHATSAPP] group.create #{key} on session #{session_id} is stranded: " \
                           "still not settled after #{NOT_SETTLED_WAITS.size + 1} attempts")
        raise
      end
      Kernel.sleep(wait)
      retry
    end
  end

  def group_info(command)
    model::GroupInfo.from_h(client.call(command))
  end

  def list_groups(command)
    Array(client.call(command)).map { |info| model::GroupInfo.from_h(info) }
  end

  def leave_group(command)
    client.call(command)
    true
  end

  # WhatsApp refuses participants one at a time -- a privacy setting, the group's
  # creator, somebody who left recently -- so the answer is a row each and `ok` says only
  # that the command ran. The connector fails the command when nothing was carried out,
  # and this reaches the same verdict from the rows: a caller told `ok` and handed a
  # refusal for every participant it named has had nothing done, which both controllers
  # already turn into the message an operator reads.
  #
  # A partial refusal is not an error. Reporting the participants that were added as not
  # added is a worse answer, and the caller reads the rows to find out which is which.
  def update_group_participants(command)
    rows = Array(client.call(command))
    raise Whatsapp::Session::Errors::GroupParticipantNotAllowed if wholly_refused?(rows)

    rows
  end

  def update_group_name(command)
    client.call(command)
    true
  end

  def update_group_description(command)
    client.call(command)
    true
  end

  def update_group_photo(command)
    client.call(command)
    true
  end

  def update_group_setting(command)
    client.call(command)
    true
  end

  def group_invite_code(command)
    result = client.call(command)
    result.is_a?(Hash) ? result['code'] : result
  end

  def group_join_requests(command)
    Array(client.call(command))
  end

  def handle_group_join_requests(command)
    Array(client.call(command))
  end

  private

  def wholly_refused?(rows)
    rows.present? && rows.all? do |row|
      row.is_a?(Hash) &&
        row.stringify_keys['code'].to_s == Whatsapp::Session::Errors::GroupParticipantNotAllowed::CODE
    end
  end

  def refresh(command)
    model::MediaRef.from_h(client.call(command))
  end

  def session_id
    id = provider_config['session_id']
    raise Whatsapp::Session::Errors::InvalidConfig, 'inbox has no session id' if id.blank?

    id
  end

  # The blob endpoint is authenticated with a token the instances publish in the
  # registry, so an operator has nothing to configure: whoever can read the Redis can
  # read the media.
  def fetch_blob(ref)
    headers = (ref.headers || {}).merge('Authorization' => "Bearer #{client.media_token(ref.url)}")
    file = Down.download(ref.url, headers: headers, max_size: MAX_MEDIA_BYTES)
    model::MediaPayload.new(io: file, mime: ref.mime || file.content_type, filename: file.original_filename, size: file.size)
  rescue Down::NotFound => e
    raise Whatsapp::Session::Errors::MediaUnavailable, "media is gone: #{e.message}"
  rescue Down::ClientError => e
    # A refused request is not a missing file, and the difference decides what the agent
    # sees: media that is gone marks the message unsupported for good, while a connector
    # that will not accept our token is an operational problem the job should retry and
    # then surface as a failed job.
    raise Whatsapp::Session::Errors::Unauthorized, "connector refused the media request: #{e.message}" if refused?(e)

    raise Whatsapp::Session::Errors::MediaUnavailable, "media is gone: #{e.message}"
  rescue Down::TooLarge => e
    raise Whatsapp::Session::Errors::MediaTooLarge, e.message
  rescue Down::Error => e
    raise Whatsapp::Session::Errors::ProviderUnavailable, "media fetch failed: #{e.message}"
  end

  def refused?(error)
    [401, 403].include?(error.response&.code.to_i)
  end
end
