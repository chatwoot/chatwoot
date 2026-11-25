# Prepended to Channel::Whatsapp. Everything the session family needs from the channel
# lives here, so the model itself only gains the provider list and this prepend, keeping
# the file (a heavy upstream-merge conflict point) untouched.
#
# Each override answers for the session providers and falls straight back to `super` for
# the legacy and cloud ones, so no existing provider changes behavior.
module Whatsapp::Session::ChannelExtension # rubocop:disable Metrics/ModuleLength
  # Registers the eligibility gate as a real validation so it covers both paths that can
  # put an inbox on a session provider: creating one and converting an existing one
  # (`convert_provider!` pre-validates with `valid?` before it persists anything).
  def self.prepended(base)
    base.validate :validate_provider_eligible
    base.validate :validate_history_media_settings, if: :session_provider?
    base.after_update_commit :resume_history_media, if: :saved_change_to_provider_config?
    base.after_update_commit :handle_provider_config_change, if: :saved_change_to_provider_config?
    # Prepended so it runs before the model's own teardown callback. It is the only thing
    # that tells the destroy path apart from an explicit disconnect, which reaches the
    # same method through the inboxes controller.
    base.before_destroy :begin_session_teardown, prepend: true
  end

  def session_provider?
    Whatsapp::Session::Registry.session_provider?(provider)
  end

  # True for the legacy session providers too: callers that ask this want "is this a
  # paired phone" (no messaging window, no templates), not "is this served here".
  def session_family?
    Whatsapp::Session::Registry.session_family?(provider)
  end

  # Surfaced on the inbox payload so the dashboard gates features by capability instead
  # of by provider name.
  def session_capabilities
    Whatsapp::Session::Registry.capabilities_for(self)
  end

  # The channel talks to its provider in legacy provider terms, so it gets the facade;
  # everything inside the session layer asks for `session_backend` instead and speaks
  # the canonical command API.
  def provider_service
    return super unless session_provider?

    Whatsapp::Session::Facade.new(self)
  end

  def session_backend
    Whatsapp::Session::Registry.backend_for(self)
  end

  # Not a delegate on the model, unlike `setup_channel_provider`: pairing by code is a
  # session-family action, and the legacy services have nothing to answer it with.
  def request_pairing_code
    raise Whatsapp::Session::Errors::NotSupported, "#{provider} does not pair by code" unless session_provider?

    provider_service.request_pairing_code
  end

  # Two callers reach this, and they want opposite things. `convert_provider!` is neither:
  # it goes to the provider service directly.
  #
  # Destruction goes ahead whether or not the provider answered, which is why the model
  # swallows a teardown failure, and why the registration is released separately: the
  # teardown stops at the disconnect when that fails, deliberately, because on a
  # conversion the webhook has to survive a rollback. There is no inbox left for it to
  # survive for, so it goes.
  #
  # An explicit disconnect is an operator waiting for an answer. A failure travels instead
  # of being logged, because reporting a session closed while it is still live leaves them
  # with a connected number and a dashboard that disagrees. The registration stays for the
  # same reason: a live session still needs somewhere to deliver.
  def disconnect_channel_provider
    return super unless session_provider?

    unless @session_teardown
      # A logout, not the teardown: the inbox stays, and the session id with it (see
      # Facade#logout_channel_provider). Not `backend.disconnect` either, which would leave
      # the device linked on the phone.
      provider_service.logout_channel_provider
      return session_backend.release_registration
    end

    super
  ensure
    session_backend.release_registration if @session_teardown && session_provider?
  end

  def begin_session_teardown
    @session_teardown = true
  end

  # A session provider fetches outbound media from Rails itself, so on an installation
  # where it cannot reach the public frontend URL (local Active Storage behind a private
  # network) the operator points INTERNAL_HOST_URL at something it can. Setting it is the
  # whole opt-in: unlike the Baileys flag this replaces, there is nothing else to turn on.
  #
  # Never for a hosted provider, though. The variable is a deployment-wide address, and an
  # installation that runs a connector alongside a hosted inbox would otherwise hand that
  # inbox a host on the other side of its own firewall: every outbound attachment on it
  # would fail, and nothing about the failure would point at this setting.
  def use_internal_host?
    return super unless session_provider?

    ENV['INTERNAL_HOST_URL'].present? && !Whatsapp::Session::Registry.hosted?(self)
  end

  # Both account limits in one write, which is one broadcast. The model has a setter per
  # limit and each of them persists and broadcasts the whole provider_connection; the two
  # cable payloads are separate jobs with no order between them, so the first, still
  # carrying the cap from before this poll, can arrive last and put a stale banner back on
  # a record that is already right. The normalization mirrors those setters, nil meaning
  # "not reported this time" in both.
  def update_account_limits!(limits)
    limits = (limits || {}).with_indifferent_access
    updates = {}
    updates['reachout_time_lock'] = limits[:reachout_time_lock].deep_stringify_keys unless limits[:reachout_time_lock].nil?
    unless limits[:new_chat_cap].nil?
      updates['new_chat_cap'] = limits[:new_chat_cap].to_h.deep_stringify_keys.slice(*Channel::Whatsapp::NEW_CHAT_CAP_KEYS)
    end
    return if updates.empty?

    with_lock { update_provider_connection!(provider_connection.merge(updates)) }
  end

  # Telling WhatsApp a message was received is an agent's act, and an import is not one.
  # These are messages the contact sent long ago, or while nobody was watching: reading
  # them on the operator's behalf puts the second tick on the contact's screen for a
  # message no human has opened, and with `mark_as_read` on it empties a year of unread
  # badges on the phone.
  #
  # Guarded here, without the `session_provider?` fallback the rest of this file uses, on
  # purpose: the legacy path acknowledges from inside `build_and_save_message` and has no
  # notion of an imported row, so the guard has to sit where both paths pass. The session
  # writer stands down on its own (`MessageWriter#acknowledge`), so this is the only check
  # the Baileys import gets and it costs the live path a thread-local read.
  def received_messages(messages, conversation)
    return if Import::SilentWrite.on?

    super
  end

  def supports_reactions?
    return super unless session_provider?

    session_capabilities.include?('reactions')
  end

  # Three fields the legacy providers have no equivalent for. They are admin-only for the
  # same reason the QR is: a pairing code links the WhatsApp account. Built here so the
  # REST payload and the Action Cable push cannot drift, since both call this.
  def provider_connection_admin_data(connection = provider_connection)
    data = super
    return data unless session_provider?

    data.merge(connection.slice('pairing_code', 'quarantine', 'ban').compact_blank.symbolize_keys)
  end

  # Up, or down but still paired: a session the connector will bring back by itself, and so
  # one that has to hear about a new proxy before it does. `connecting` alone does not
  # count: that is also a QR pairing in progress, which a resume would only interrupt.
  def resumable_session?
    connection = provider_connection.to_h
    connection['connection'] == 'open' ||
      Whatsapp::Session::ConnectionStateWriter::PAIRING_KEYS.any? { |key| connection[key].present? }
  end

  private

  # Two things a session inbox's config can change that the provider has to be told about,
  # and neither of them changes the provider key, so nothing else in the layer notices.
  #
  # Inline, like the teardown a destroy and a conversion already run: one of these needs
  # the credentials that just left the record, and a job would have to carry them through
  # Redis to use them.
  def handle_provider_config_change
    return unless session_provider?
    # A conversion changes the provider and the config in the same save, and
    # `convert_provider!` has already torn the old provider down and emptied the record.
    return if saved_change_to_provider?

    previous = self.class.find(id)
    previous.provider_config = saved_change_to_provider_config.first || {}
    let_go_of(previous) if moved_instance?(previous)
    follow_connect_request_change
  rescue Whatsapp::Session::Errors::Error => e
    # This runs after the commit, so raising would answer a save that already succeeded
    # with a 500, and neither half of this is something the save depended on.
    Rails.logger.warn("[WHATSAPP SESSION] provider config change on inbox ##{inbox&.id} left the provider behind: #{e.message}")
  end

  # The connector holds the proxy it was last given until a connect names another, and it
  # resumes a dropped session through that same proxy. So a change goes out while the
  # session is up, and also while it is down but still paired, which is the likeliest time
  # to change it: the proxy failed and took the session with it. A pairing that ended (a
  # logout, a wrong number) or never happened has nothing to resume, and gets the proxy
  # with its next connect, which is the operator's to ask for.
  #
  # The connect goes through a job because the save has already committed: a connector that
  # cannot be reached right now would otherwise leave it on the old proxy for good, since
  # saving the same address again changes nothing and sends nothing.
  def follow_connect_request_change
    Whatsapp::Session::ApplyProxyJob.perform_later(id) if proxy_changed? && resumable_session?
  end

  def proxy_changed?
    before, after = saved_change_to_provider_config
    before.to_h['proxy_url'].presence != after.to_h['proxy_url'].presence
  end

  # False for every save that did not touch the credentials, and for a backend with no
  # instance to name: the connector keys its session by an id this cannot change.
  def moved_instance?(previous)
    fingerprint = Whatsapp::Session::Registry.instance_fingerprint(previous)
    fingerprint.present? && fingerprint != Whatsapp::Session::Registry.instance_fingerprint(self)
  end

  # The inbox now points at another instance of the same provider: a rotated token, a moved
  # address, a second instance on the same hosted service. The connection record goes on
  # reporting the session the previous instance had, down to the number it was paired with,
  # while the new one has never been told where to deliver: the inbox reads as connected and
  # receives nothing until somebody thinks to reconnect it.
  #
  # So the record is emptied, which is what puts the dashboard back on "connect", and the
  # registration on the instance being left behind is withdrawn. Registering the new one is
  # deliberately not done here: that is what `connect` does, it is the operator's action,
  # and on an instance that is not paired it would start a pairing nobody is watching.
  def let_go_of(previous)
    with_lock { update_provider_connection!({}) }
    Whatsapp::Session::Registry.backend_for(previous).release_registration
  end

  # Who may stand up an inbox on this provider: the account toggles while the new
  # providers roll out, the deprecation switch once the frozen ones are withdrawn.
  #
  # Enforced where the record is written rather than where it is offered, because a
  # picker that hides a provider is not a gate: the API, the rake conversion tasks and a
  # `?provider=` URL all reach this code and none of them read the dashboard. Only new
  # records and provider changes are checked, so flipping a switch back never makes an
  # inbox that already exists unsaveable.
  # When the automatic fetch comes to cover more than it did, the files it now covers are
  # collected and fetched: those that waited while it was off, and those a narrower window
  # had left out. Nothing else would ask for them, since importing again writes nothing.
  def resume_history_media
    history_media = Whatsapp::Session::HistoryMedia
    before, after = saved_change_to_provider_config
    return unless session_provider? && history_media.enabled?(after)
    return unless !history_media.enabled?(before) || history_media.window_days(after) > history_media.window_days(before)

    Whatsapp::Session::HistoryMediaJob.kick(inbox, requeue: true)
  end

  # What the inbox settings page writes for the history files (Whatsapp::Session::
  # HistoryMedia). Both are optional, and only the documented shapes are kept: a window of
  # zero days, or a string, would turn the automatic fetch off without saying so.
  def validate_history_media_settings
    config = provider_config.to_h
    fetch = config[Whatsapp::Session::HistoryMedia::FETCH_KEY]
    days = config[Whatsapp::Session::HistoryMedia::WINDOW_KEY]
    errors.add(:provider_config, 'history_media_fetch must be true or false') unless fetch.nil? || [true, false].include?(fetch)
    errors.add(:provider_config, 'history_media_days must be a positive whole number') unless days.nil? || (days.is_a?(Integer) && days.positive?)
  end

  def validate_provider_eligible
    return unless new_record? || provider_changed?

    reason = ineligible_reason
    errors.add(:provider, I18n.t("errors.inboxes.channel.#{reason}")) if reason
  end

  def ineligible_reason
    return 'provider_withdrawn' if legacy_provider? && !Whatsapp::Session::Registry.legacy_creatable?
    return 'provider_not_enabled_for_account' if session_provider? && !account&.whatsapp_session_provider_enabled?(provider)

    nil
  end

  def legacy_provider?
    Whatsapp::Session::Registry.descriptor(provider)&.legacy? || false
  end

  # Session backends validate their config against the descriptor's field list, never
  # against the provider itself: saving an inbox must not depend on a provider being up.
  def validate_provider_config
    return super unless session_provider?

    descriptor = Whatsapp::Session::Registry.descriptor(provider)
    return errors.add(:provider, I18n.t('errors.inboxes.channel.provider_unavailable')) unless descriptor.available?

    invalid_keys = descriptor.backend_class.validate_config(provider_config || {})
    return if invalid_keys.empty?

    errors.add(:provider_config, I18n.t('errors.inboxes.channel.invalid_provider_config', keys: invalid_keys.join(', ')))
  end

  # Two identifiers every session inbox needs, both generated once and never shown: the
  # webhook secret that authenticates a provider callback (the URL carries it and the
  # controller compares it), and the session id the provider holds the session under.
  #
  # Deliberately not the phone number: the connector keys its whatsmeow store by this id,
  # and a re-pairing under a different number would otherwise land on top of the previous
  # session's device keys.
  def ensure_webhook_verify_token
    return super unless session_provider?

    provider_config['webhook_verify_token'] = kept('webhook_verify_token') { SecureRandom.hex(16) }
    # A new one when the provider changes. Leaving the provider tears the session down, and
    # the connector forgets a deleted session, epoch counter included: back on native under
    # the old id, the new pairing would start at epoch 1 under the epoch and position kept for
    # the old one, and be dropped (fazer-ai/chatwoot#852).
    provider_config['session_id'] = provider_changed? ? SecureRandom.uuid : kept('session_id') { SecureRandom.uuid }
  end

  # Written from the stored value rather than from whatever came in, because
  # provider_config is permitted wholesale by the inbox API and neither of these keys is
  # shown on the form. An update that leaves one out used to mint a new one: a new session
  # id orphans the session the connector is still holding under the old one, and a new
  # webhook secret leaves the provider posting to a URL this app now answers 401, so the
  # inbox goes quiet until somebody reconnects it.
  #
  # One handed in by a caller is ignored for the same reason it is not asked for: it could
  # name another inbox's session, or make the secret a value somebody else chose.
  def kept(key)
    stored = persisted? ? (provider_config_was || {})[key] : nil
    stored.presence || yield
  end
end
