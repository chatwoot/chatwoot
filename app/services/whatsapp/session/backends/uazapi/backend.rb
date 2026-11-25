# The `uazapi` provider: a hosted WhatsApp gateway the customer already pays for, reached
# over HTTP. Chatwoot never provisions an instance here and never holds an admin token:
# the operator brings a base URL and an instance token, and this backend drives that one
# instance.
#
# Where the connector answers commands over Redis and pushes canonical events, this one
# calls REST endpoints and receives a webhook that WebhookTranslator turns into the same
# events. Above this class nothing knows the difference.
#
# WHAT IS PROVEN. The endpoints exercised against a live instance on 19/08/2026 are
# `/instance/{connect,disconnect,status,wa_messages_limits}`, `/webhook`, `/send/*`,
# `/message/{react,edit,markread,download,presence}`, `/chat/{check,details}` and
# `/group/{create,list,updateParticipants}`. The rest follow the provider's own docs and
# are confirmed by the end-to-end checklist, not by a recorded response. Two are known
# NOT to exist on that build: `/instance/logout` and `/group/invitelink` both answer 405,
# which is why logging out is a disconnect and why `group_invites` is not declared.
class Whatsapp::Session::Backends::Uazapi::Backend < Whatsapp::Session::Backend
  include Whatsapp::Session::Backends::Uazapi::Backend::State
  include Whatsapp::Session::Backends::Uazapi::Backend::Messages
  include Whatsapp::Session::Backends::Uazapi::Backend::Groups

  # A cap on what a single media download may pull into the Rails process. WhatsApp itself
  # stops well below this; the limit is there so a wrong URL cannot fill a disk.
  MAX_MEDIA_BYTES = 100.megabytes

  # Withdrawing the webhook is always a goodbye: a destroy, a conversion, an inbox pointed
  # somewhere else. Nothing reads the answer and one of those callers is a request the
  # administrator is waiting on, so an instance that has stopped answering costs seconds
  # rather than the full ceiling.
  RELEASE_TIMEOUT = 5

  # How long a code pairing waits for a disconnect to take effect before connecting
  # anyway. See `restart_for_code_pairing`.
  DISCONNECT_SETTLE_TRIES = 4
  DISCONNECT_SETTLE_WAIT = 0.5

  # The events this inbox asks for. `chats`, `contacts` and `labels` are the instance's own
  # CRM chatter and are never subscribed: everything Chatwoot needs is in these five.
  WEBHOOK_EVENTS = %w[connection messages messages_update presence groups].freeze

  # `history` is the sixth, and it is asked for only by an inbox that turned the sync on.
  # It is not a stream of its own: the same event carries the initial dump the phone sends
  # after pairing and the answer to every on-demand request, and it arrives in batches of
  # up to 200 messages. An inbox that does not want the history should not be paying to
  # receive it and then throw it away.
  HISTORY_EVENT = 'history'.freeze

  # Our own sends come back as an echo, and nothing is excluded from the subscription:
  # the echo is the only way to learn that a send whose answer never arrived actually
  # landed. `/send/*` can accept a message and then time out on the way back, and the
  # sender treats that as retryable, so without the echo the retry posts a second copy
  # and the contact reads the same message twice. The echo carries the `track_id` this
  # inbox generated, `EchoMatcher` fills the row's source_id from it, and
  # `Base::SendOnChannelService` then declines to send a message that already has one.
  # A second row is not the risk it looks like either: the same matcher recognizes the
  # echo of a message already stored.
  WEBHOOK_EXCLUDES = [].freeze

  class << self
    def provider_key
      'uazapi'
    end

    def capabilities
      Whatsapp::Session::Registry.descriptor('uazapi').capabilities
    end

    # The QR rotates about every 20 seconds and only the first one arrives on the webhook,
    # so an inbox that is not polled sits on a code that stopped working. The account
    # limits are not pushed at all.
    def state_polling?
      true
    end

    # Every webhook is its own Sidekiq job, so waiting on the download holds only that one
    # message, and consumers of `message_created` (an agent reading an image) see the file.
    def inline_media? = true

    # Whether the instance is somebody else's host is not a question its address can
    # answer. A self-hosted one is reached by whatever name the network gives it, from a
    # compose service to an internal FQDN to a plain address, and reading any of those as
    # a signal gets a deployment wrong in one direction or the other. Only whoever set it
    # up knows, and for this provider the answer is fixed: uazapi is sold as a service and
    # the customer points an inbox at an instance it runs, so it is always on the far side
    # of the deployment's network and always reachable at the public address. There is no
    # build of it to stand up next to Rails, which is what an internal address would be
    # for.
    def hosted?(_channel)
      true
    end

    # The token is what tells two instances apart: on the hosted service they share a base
    # URL and nothing else in the config belongs to them. Digested, because this is written
    # into a job payload and waits in Redis until the job runs, and a credential does not
    # belong there.
    def instance_fingerprint(channel)
      config = channel.provider_config || {}
      return if config['token'].blank?

      # Normalized the way the client normalizes it, so an address that differs only in a
      # trailing slash is not read as another instance: that would empty a live connection
      # record and withdraw a webhook that was never pointed anywhere else.
      Digest::SHA256.hexdigest("#{config['base_url'].to_s.chomp('/')}\n#{config['token']}")
    end

    # Resolved on every call rather than held in a constant: a constant captured when this
    # file loads keeps the class from before the last reload.
    def translator
      Whatsapp::Session::Backends::Uazapi::WebhookTranslator
    end

    # Shape only, never a request: saving an inbox must not depend on the provider being
    # up, and a wrong token shows up as `invalid_credentials` on the first connect.
    def validate_config(provider_config)
      config = (provider_config || {}).with_indifferent_access
      keys = []
      keys << 'base_url' unless reachable_http_url?(config[:base_url])
      keys << 'token' if config[:token].blank?
      keys
    end

    private

    # The instance address is set by whoever administers the account, and every method on
    # this backend sends that account's credentials to it and puts the answer on the
    # dashboard. An address inside the deployment's own network would turn the inbox form
    # into a way of reading services that were never meant to be reachable from it, so one
    # is refused unless the operator has said the private network is fair game.
    def reachable_http_url?(value)
      return false unless address.http_url?(value)

      SafeFetch.allow_private_network? || !address.url?(value)
    end

    def address = Whatsapp::Session::PrivateAddress
  end

  # Resolved when called, never held in a constant, for the same reason as above.
  def model = Whatsapp::Session::Model
  def commands = Whatsapp::Session::Model::Commands

  def client
    @client ||= Whatsapp::Session::Backends::Uazapi::Client.new(
      base_url: provider_config['base_url'], token: provider_config['token']
    )
  end

  # --- session lifecycle -----------------------------------------------------------

  # The webhook goes up first: registering it after the connect would leave the window
  # where the session opens and its first messages have nowhere to be delivered.
  def connect(command)
    register_webhook
    restart_for_code_pairing if command.pairing == 'code'
    body = { phone: (command.phone if command.pairing == 'code') }
    connection_state(client.post('/instance/connect', body))
  end

  def disconnect
    client.post('/instance/disconnect')
    nil
  end

  # There is no unpair on this provider: `/instance/logout` answers 405, so the strongest
  # thing available is dropping the connection. The credentials stay on the instance, and
  # a session paired with the wrong number is ended rather than un-paired, which is why
  # the quarantine marker (not the provider) is what keeps that account's chats out.
  def logout
    disconnect
  end

  # A teardown, not a pause: the inbox is being destroyed or converted. The instance itself
  # belongs to the customer and is never deleted from here.
  #
  # The disconnect goes first because it is the fallible half. A conversion that fails on
  # it is rolled back and the inbox stays on this provider, and withdrawing the webhook
  # before finding that out cannot be undone: the inbox would go on serving uazapi while
  # silently receiving nothing until somebody reconnected it. The other order costs
  # nothing, since the webhook is withdrawn best effort anyway.
  def delete_session
    disconnect
    withdraw_webhook
  end

  def release_registration = withdraw_webhook

  # Points the instance at this inbox's webhook URL again. The URL is not derived from
  # anything the instance knows, so a deployment that changes which host it hands out has
  # to say so: nothing else would, and the instance would go on posting at the old one.
  def ensure_registration = register_webhook

  def fetch_connection_state
    connection_state(client.get('/instance/status'))
  end

  def fetch_account_limits
    limits = client.get('/instance/wa_messages_limits') || {}
    { 'reachout_time_lock' => reachout_time_lock(limits), 'new_chat_cap' => new_chat_cap(limits) }.compact
  end

  # Asks the phone for what came before. The answer is not this call's: the provider
  # acknowledges the request and the messages arrive later on the `history` webhook, in
  # batches, and only if the phone is awake to answer at all. `count` is passed on as the
  # hint it is.
  def request_history(command)
    # The answer to this comes back on the webhook, and the webhook only carries history
    # for an instance subscribed to that event. Subscription is set at connect time, so an
    # inbox that turned the setting on afterwards would send the request and never see the
    # reply. Registering is idempotent and this runs once per backend, so a backfill
    # walking fifty chats still registers once.
    ensure_history_subscription
    client.post('/message/history-sync', {
      number: command.chat.to_jid, mode: 'history',
      count: command.count, messageid: command.before&.id
    }.compact)
    nil
  end

  # --- presence and contacts -------------------------------------------------------

  # `delay` is how long the provider holds the indicator up. Chatwoot sends a fresh one on
  # every keystroke burst, so a short hold is what keeps the bubble from sticking after
  # the agent stops typing.
  def send_chat_presence(command)
    client.post('/message/presence', { number: number(command.chat), presence: command.state, delay: 3000 })
    nil
  end

  def update_presence(command)
    client.post('/instance/presence', { presence: command.state })
    nil
  end

  # `phone` comes from `jid`, never from `query`. The whole reason anyone checks a number
  # is to learn the one WhatsApp actually knows it by (the Brazilian ninth digit is the
  # case that made this necessary), and `query` is only the echo of what we asked. It is
  # the fallback for a number that is not on WhatsApp, where `jid` comes back empty.
  def check_numbers(command)
    Array(client.post('/chat/check', { numbers: Array(command.phones) })).map do |entry|
      entry = entry.to_h
      checked = model::Address.parse(entry['jid'].presence)
      model::NumberCheck.new(
        phone: checked&.id || entry['query'], exists: entry['isInWhatsapp'].present?,
        address: model::Address.parse(entry['lid'].presence) || checked
      )
    end
  end

  def profile_picture_url(command)
    details = client.post('/chat/details', { number: number(command.party), preview: command.preview }) || {}
    command.preview ? details['imagePreview'].presence || details['image'] : details['image']
  end

  private

  # --- connection --------------------------------------------------------------------

  # Both `/instance/status` and `/instance/connect` answer with the instance under the
  # same key, so one reader serves them.
  # --- webhook -----------------------------------------------------------------------

  def register_webhook
    client.post('/webhook', webhook_body(enabled: true))
  end

  def ensure_history_subscription
    return if @history_subscribed

    register_webhook
    @history_subscribed = true
  end

  # Best effort by design: the inbox is being torn down either way, and a provider that
  # is unreachable (or that has already dropped the instance) must not keep a conversion
  # from finishing.
  def withdraw_webhook
    client.post('/webhook', webhook_body(enabled: false), timeout: RELEASE_TIMEOUT)
  rescue Whatsapp::Session::Errors::Error => e
    Rails.logger.warn("[WHATSAPP SESSION] could not withdraw the uazapi webhook of inbox ##{channel.inbox&.id}: #{e.message}")
  end

  # This provider issues a pairing code only when the connect starts from a disconnected
  # instance. Asked for one while a pairing is already in flight, it answers the state it
  # is already in: no code, and the QR it was rotating before. The operator is then left
  # on a screen waiting for a code that is never coming, which is exactly the state the
  # dashboard offers the code from. Observed against a live instance on 22/08/2026.
  #
  # Ending that attempt first is safe, because pairing by code replaces whatever pairing
  # was on screen anyway. An open session is deliberately left alone: disconnecting one
  # here would cost the pairing itself, since this provider has no logout, its disconnect
  # drops the credentials, and connecting again asks for a new QR.
  # The disconnect itself settles asynchronously, and a connect fired before it does is
  # answered with the state from before: a closed session, no code, and a pairing screen
  # that never starts, which is how this looked the first time it was run against a live
  # instance. So the connect waits for the instance to actually be down. The ceiling is
  # what an operator waits on a button they pressed, and reaching it is not fatal: the
  # connect goes out anyway and the poll picks up whatever the provider settles on.
  def restart_for_code_pairing
    return unless fetch_connection_state.connecting?

    disconnect
    DISCONNECT_SETTLE_TRIES.times do
      sleep(DISCONNECT_SETTLE_WAIT)
      break if instance_down?
    end
  end

  # The provider's raw verdict, not the one `pairing_connection` softens: what this waits
  # for is the socket being down, and a stale QR left on the instance is exactly what it
  # is waiting to stop mattering.
  def instance_down?
    status = client.get('/instance/status').to_h['instance'].to_h['status'].to_s

    CONNECTIONS.fetch(status, 'close') == 'close'
  end

  def webhook_body(enabled:)
    {
      url: webhook_url, enabled: enabled, events: subscribed_events, excludeMessages: WEBHOOK_EXCLUDES,
      addUrlEvents: false, addUrlTypesMessages: false
    }
  end

  # Always subscribed, because not listening is a decision that cannot be revisited later.
  # The phone's account of what arrived while the session was down is pushed once, right
  # after a pairing, and there is no request that fetches it afterwards: `/message/history-sync`
  # only walks backwards from a message the instance already has (`mode` accepts nothing
  # else, checked against the API). An inbox that was not subscribed at that moment has
  # lost the weekend for good.
  #
  # Subscribing is not consent to import: the handler keeps only the gap out of a pile
  # nobody asked for, and a first pairing has no coverage, so all of it is dropped.
  def subscribed_events
    WEBHOOK_EVENTS + [HISTORY_EVENT]
  end

  def history_sync?
    ActiveModel::Type::Boolean.new.cast(provider_config['history_sync']).present?
  end

  # The address this instance can reach us at. Always the public one: the instance runs on
  # the provider's infrastructure, so an address that only resolves inside this deployment
  # would leave the inbox paired and never receiving an event.
  #
  # The path carries a secret of its own, generated per inbox and never shown. It is not
  # the only check: the body carries the instance token, which the controller compares
  # too, so a URL leaked through a proxy log is not on its own enough to post events into
  # an inbox.
  def webhook_url
    host = ENV.fetch('FRONTEND_URL', nil)
    "#{host.to_s.chomp('/')}/webhooks/whatsapp/session/uazapi/#{channel.id}/#{provider_config['webhook_verify_token']}"
  end

  # --- media -------------------------------------------------------------------------

  # Filtered rather than downloaded outright, because this URL is the provider's to
  # choose: it arrives on the webhook or in the answer to `/message/download`, and an
  # instance that is hostile or merely compromised could name a link-local address and
  # have Rails read a cloud metadata endpoint and attach the answer to a conversation.
  # SafeFetch resolves the host and refuses everything that is not public, which is also
  # why an instance self-hosted on a private network needs SAFE_FETCH_ALLOW_PRIVATE_NETWORK.
  #
  # The content type is deliberately not checked: WhatsApp media is whatever a phone can
  # attach, and the type is a label here, not a decision.
  #
  # Copied out of the block because SafeFetch unlinks its tempfile the moment the block
  # returns, and these bytes are attached later, after the caller has taken its lock.
  def fetch(url, mime: nil)
    SafeFetch.fetch(url, max_bytes: MAX_MEDIA_BYTES, validate_content_type: false) do |result|
      file = Tempfile.new('uazapi-media', binmode: true)
      IO.copy_stream(result.tempfile, file)
      file.rewind
      model::MediaPayload.new(io: file, mime: mime.presence || result.content_type, filename: result.filename, size: file.size)
    end
  rescue SafeFetch::FileTooLargeError => e
    raise Whatsapp::Session::Errors::MediaTooLarge, e.message
  rescue SafeFetch::HttpError, SafeFetch::UnsafeUrlError, SafeFetch::InvalidUrlError => e
    # A status is only ever in the message, and only HttpError has one. A server error or
    # a throttle is the host having a bad minute and worth another pass; the rest is the
    # file being gone, or never having been fetchable at all.
    raise Whatsapp::Session::Errors::ProviderUnavailable, "uazapi media fetch failed: #{e.message}" if retryable_media?(e)

    raise Whatsapp::Session::Errors::MediaUnavailable, "uazapi media is gone: #{e.message}"
  rescue SafeFetch::Error, *Whatsapp::Session::Backends::Uazapi::Client::TRANSPORT_ERRORS => e
    # SafeFetch names some transport failures and not others: a host that refuses or
    # resets the connection comes out as the raw system error, which would escape this
    # backend as itself and miss the fetch job's retry policy entirely.
    raise Whatsapp::Session::Errors::ProviderUnavailable, "uazapi media fetch failed: #{e.message}"
  end

  def retryable_media?(error)
    status = error.message.to_i
    status >= 500 || status == 429
  end

  # --- addressing ----------------------------------------------------------------------

  # What the provider's `number` field takes: a bare phone for a person, the full JID for a
  # group, and the LID JID when that is all we know the contact by.
  def number(address)
    return if address.nil?

    address.phone? ? address.id : address.to_jid
  end
end
