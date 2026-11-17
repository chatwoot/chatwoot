# The provider catalog. Answers "who serves this channel", "what can it do" and "what
# does its form look like" for every WhatsApp provider, including the legacy and cloud
# ones it does not serve, so the dashboard can drive itself from capabilities instead of
# provider-name literals.
#
# Most of the length below is the catalog literal itself, and it grows by a table entry
# every time a provider is described, so the module-length metric is measuring the data
# rather than the behavior.
module Whatsapp::Session::Registry # rubocop:disable Metrics/ModuleLength
  Descriptor = Whatsapp::Session::ProviderDescriptor
  Field = Whatsapp::Session::ProviderDescriptor::Field

  MARK_AS_READ = Field.new(name: 'mark_as_read', type: 'boolean', default: true, advanced: true).freeze
  PRESENCE_SUBSCRIBE = Field.new(name: 'presence_subscribe', type: 'boolean', default: false, advanced: true).freeze
  # Off by default, and behind the advanced toggle: the phone answers a history request
  # with everything it has (947 messages for one chat, measured), so an inbox opts into
  # that rather than discovering it on the first connect.
  HISTORY_SYNC = Field.new(name: 'history_sync', type: 'boolean', default: false, advanced: true).freeze
  # The way out to WhatsApp for this inbox's session. A password field because the URL
  # carries the proxy's credentials, but not a secret: a secret input starts empty and an
  # empty one is never saved, so the settings page could neither show that a proxy is set
  # nor take it away, and provider_config reaches only administrators anyway (#743).
  # Advanced: optional, and most inboxes go out without one.
  PROXY_URL = Field.new(name: 'proxy_url', type: 'password', advanced: true).freeze

  DESCRIPTORS = [
    Descriptor.new(
      key: 'native',
      backend: 'Whatsapp::Session::Backends::Connector::Backend',
      pairing_modes: %w[qr code],
      # No session_import: that is the Baileys credential import, which whatsmeow cannot
      # consume, and there is no such command in the contract. Its replacement for the
      # same problem (pairing without a QR the operator can scan) is the passkey relay,
      # which rides on the pairing commands.
      #
      # No account_limits either. The contract lets a connection state carry
      # `reachout_time_lock` and `new_chat_cap`, and the connector's `session.status`
      # answers connection, phone number and LID and nothing else: whatsmeow surfaces no
      # WhatsApp Business messaging limit for it to fill them with. Nothing asks for them
      # on this provider today, because a connector session is pushed rather than polled,
      # so what the declaration bought was a promise on the inbox payload that the next
      # caller would have read as an answer.
      #
      # `calls` is what lets the offer through the dispatcher. It does not promise a call
      # can be answered here, and it puts no policy on the connect: the call rings on the
      # operator's phone, and the inbox shows that it happened. Asking the connector to
      # refuse would end the call on every device of the account, the phone included
      # (fazer-ai/chatwoot#850).
      #
      # `history_sync` is the phone's history, published by the connector as `history.sync`
      # and asked for with `history.request`. The field decides only whether the archive is
      # filed: the connect always asks for history, because what arrived while the session
      # was down comes in the same dump, and that part is filed with the field off too.
      capabilities: %w[
        qr_pairing code_pairing echo_by_reserved_id edit revoke reactions typing presence
        presence_subscribe read_receipts mark_unread check_number profile_picture groups
        group_management group_admin group_invites group_join_requests media_download calls
        history_sync
      ],
      fields: [PROXY_URL, MARK_AS_READ, PRESENCE_SUBSCRIBE, HISTORY_SYNC]
    ),
    Descriptor.new(
      key: 'uazapi',
      backend: 'Whatsapp::Session::Backends::Uazapi::Backend',
      beta: true,
      pairing_modes: %w[qr code],
      # No group_invites: the captured build answers 405 on `/group/invitelink`, and the
      # group snapshot it does serve carries no invite code either. A capability that is
      # declared and then refused by the provider is a button that fails in the agent's
      # face, so it is not declared.
      capabilities: %w[
        qr_pairing code_pairing edit revoke reactions typing presence read_receipts check_number
        profile_picture groups group_management group_admin account_limits media_download history_sync
      ],
      fields: [
        Field.new(name: 'base_url', type: 'url', required: true),
        Field.new(name: 'token', type: 'password', required: true, secret: true),
        MARK_AS_READ,
        PRESENCE_SUBSCRIBE,
        HISTORY_SYNC
      ]
    ),
    # Legacy: described so the UI can label and gate an existing inbox, never served here.
    # history_sync, despite being frozen: this one is not a new feature so much as the
    # provider's own data finally being kept. Baileys is the only provider that delivers
    # WhatsApp's offline replay, so a message that arrived while a Baileys inbox was down
    # is recoverable here and nowhere else.
    Descriptor.new(
      key: 'baileys',
      legacy: true,
      pairing_modes: %w[qr],
      capabilities: %w[
        qr_pairing session_import echo_by_reserved_id edit revoke reactions typing presence presence_subscribe
        read_receipts mark_unread check_number profile_picture groups group_management group_admin
        group_invites group_join_requests account_limits media_download history_sync
      ]
    ),
    Descriptor.new(
      key: 'zapi',
      legacy: true,
      pairing_modes: %w[qr],
      capabilities: %w[qr_pairing revoke reactions read_receipts check_number]
    ),
    # typing and read_receipts included: the Cloud service implements both
    # (`toggle_typing_status` and `read_messages` post to the Graph API), and the
    # dashboard gates them by capability now.
    Descriptor.new(key: 'whatsapp_cloud', family: 'cloud',
                   capabilities: %w[reactions typing read_receipts media_download calls]),
    Descriptor.new(key: 'default', family: 'cloud', capabilities: %w[media_download])
  ].index_by(&:key).freeze

  class << self
    def descriptor(provider)
      DESCRIPTORS[provider.to_s]
    end

    def descriptors
      DESCRIPTORS.values
    end

    # Providers this layer serves. Legacy session providers are deliberately excluded:
    # they answer through their own services until they are removed.
    def session_provider?(provider)
      Whatsapp::Session::PROVIDERS.include?(provider.to_s)
    end

    # Whether this inbox's commands run through the session layer's own backend, which is
    # what makes the capability list the authority on what it can carry out. A legacy
    # provider is in the session family and is not this: its own service decides.
    def session_backed?(channel)
      descriptor = descriptor(channel.provider)
      descriptor.present? && descriptor.session? && !descriptor.legacy?
    end

    # The QR/pairing family, legacy providers included. What sets it apart from the cloud
    # family is behavioral: a paired session is a real WhatsApp client, so there is no
    # 24-hour messaging window and no template requirement.
    def session_family?(provider)
      descriptor(provider)&.session? || false
    end

    # The class that turns this provider's webhook body into canonical events, or nil when
    # the provider does not deliver over HTTP (the connector publishes canonical events
    # already) or the inbox has left the session layer.
    def translator_for(channel)
      descriptor(channel.provider)&.backend_class&.translator
    end

    # Whether this inbox's provider runs outside the deployment's network. Unknown counts
    # as hosted: the public address is the one that works everywhere an internal one is
    # not strictly needed.
    def hosted?(channel)
      backend = descriptor(channel.provider)&.backend_class
      backend.nil? || backend.hosted?(channel)
    end

    # See `Backend.instance_fingerprint`. nil for a provider this layer does not serve, so
    # a caller comparing two of them is never fenced by a pair of nils.
    def instance_fingerprint(channel)
      descriptor(channel.provider)&.backend_class&.instance_fingerprint(channel)
    end

    def backend_for(channel)
      descriptor = descriptor(channel.provider)
      raise Whatsapp::Session::Errors::InvalidConfig, "#{channel.provider} is not served by the session layer" unless descriptor&.served?

      # A descriptor can name a backend that has not shipped yet, which is how a provider
      # gets described and labelled before it can be created. Saying so beats the
      # NoMethodError that constantizing nothing produces.
      backend = descriptor.backend_class
      raise Whatsapp::Session::Errors::NotSupported, "#{channel.provider} has no backend in this build" if backend.nil?

      backend.new(channel)
    end

    # The capabilities of a channel as the dashboard should see them: the descriptor's
    # list, minus what the instance turned off.
    def capabilities_for(channel)
      descriptor = descriptor(channel.provider)
      return [] if descriptor.nil?

      capabilities = descriptor.capabilities
      capabilities -= Whatsapp::Session::Capabilities::GROUP_CAPABILITIES unless groups_enabled?
      capabilities
    end

    # Kill switch for the whole group subsystem, legacy providers included: the Baileys
    # service delegates here so the capability list and `allow_group_creation` can never
    # disagree. The Baileys-era name still works, so an existing deployment does not have
    # to change its env on upgrade.
    def groups_enabled?
      # `.presence`, not just the nil check: a compose file that lists the variable with
      # no value, or a panel field left blank, sets it to the empty string, and an empty
      # string is truthy here. Read as a value it takes the fallback away, so a
      # deployment that never migrated off the Baileys-era name loses every group
      # capability on upgrade -- which is the one thing this fallback exists to prevent.
      value = ENV.fetch('WHATSAPP_GROUPS_ENABLED', nil).presence || ENV.fetch('BAILEYS_WHATSAPP_GROUPS_ENABLED', 'false')
      value == 'true'
    end

    # Whether the frozen providers are still offered when standing up a new inbox. They
    # are frozen, not withdrawn: existing inboxes keep working either way, and this is
    # what the deprecation flips when it starts.
    def legacy_creatable?
      ActiveModel::Type::Boolean.new.cast(ENV.fetch('WHATSAPP_LEGACY_PROVIDERS_CREATABLE', true))
    end

    def available_providers
      descriptors.select(&:available?).map(&:key)
    end
  end
end
