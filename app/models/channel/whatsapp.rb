# rubocop:disable Layout/LineLength
# == Schema Information
#
# Table name: channel_whatsapp
#
#  id                             :bigint           not null, primary key
#  business_management_token      :text
#  message_templates              :jsonb
#  message_templates_last_updated :datetime
#  phone_number                   :string           not null
#  phone_number_health            :jsonb            not null
#  phone_number_health_checked_at :datetime
#  phone_number_health_error      :string(500)
#  provider                       :string           default("default")
#  provider_config                :jsonb
#  provider_connection            :jsonb
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  account_id                     :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_connection_state                   (((provider_connection ->> 'connection'::text))) WHERE ((provider)::text = ANY ((ARRAY['baileys'::character varying, 'zapi'::character varying, 'native'::character varying, 'uazapi'::character varying])::text[]))
#  index_channel_whatsapp_on_phone_number                    (phone_number) UNIQUE
#  index_channel_whatsapp_on_phone_number_health_checked_at  (phone_number_health_checked_at)
#  index_channel_whatsapp_provider_connection                (provider_connection) WHERE ((provider)::text = ANY ((ARRAY['baileys'::character varying, 'zapi'::character varying, 'native'::character varying, 'uazapi'::character varying])::text[])) USING gin
#  index_channel_whatsapp_session_id                         (((provider_config ->> 'session_id'::text))) UNIQUE WHERE ((provider)::text = ANY ((ARRAY['native'::character varying, 'uazapi'::character varying])::text[]))
#
# rubocop:enable Layout/LineLength

class Channel::Whatsapp < ApplicationRecord # rubocop:disable Metrics/ClassLength
  include Channelable
  include Reauthorizable
  # Session providers (native, uazapi) answer through this module; every override falls
  # back to `super` for the cloud and legacy providers.
  prepend Whatsapp::Session::ChannelExtension

  self.table_name = 'channel_whatsapp'
  EDITABLE_ATTRS = [:phone_number, :provider, { provider_config: {} }].freeze
  encrypts :business_management_token if Chatwoot.encryption_configured?

  # default at the moment is 360dialog lets change later.
  PROVIDERS = (%w[default whatsapp_cloud baileys zapi] + Whatsapp::Session::PROVIDERS).freeze
  REACTION_SUPPORTED_PROVIDERS = %w[whatsapp_cloud baileys zapi].freeze
  # UI-relevant subset of the baileys new-chat message cap payload that we persist in
  # provider_connection. server_sent_timestamp is intentionally dropped (it changes on every
  # snapshot, so keeping it would make the 5-min poll re-broadcast every cycle for no reason).
  NEW_CHAT_CAP_KEYS = %w[capping_status ote_status mv_status total_quota used_quota cycle_start_timestamp cycle_end_timestamp].freeze
  before_validation :ensure_webhook_verify_token
  before_validation :keep_app_secret, if: -> { provider.in?(%w[whatsapp_cloud default]) }
  before_validation :ensure_webhook_token

  validates :provider, inclusion: { in: PROVIDERS }
  validates :phone_number, presence: true, uniqueness: true
  validate :validate_provider_config
  validate :validate_app_secret, if: :app_secret_required?

  has_one :inbox, as: :channel, dependent: :destroy

  after_create :sync_templates
  after_update_commit :log_credentials_transfer, if: :saved_change_to_provider_config?
  before_destroy :teardown_webhooks
  before_destroy :disconnect_channel_provider, if: -> { provider_service.respond_to?(:disconnect_channel_provider) }
  after_commit :setup_webhooks, on: :create, if: :should_auto_setup_webhooks?

  def name
    'Whatsapp'
  end

  def supports_reactions?
    REACTION_SUPPORTED_PROVIDERS.include?(provider)
  end

  # Mirrors Channel::TwilioSms#voice_enabled? so the call subsystem can duck-type across providers.
  # Meta's Calling API is available to any whatsapp_cloud inbox (embedded-signup or manual keys);
  # only 360dialog (default provider) can't reach the call APIs.
  def voice_enabled?
    voice_calling_supported? &&
      provider_config['calling_enabled'].present? &&
      account.feature_enabled?('channel_voice')
  end

  # Mutes only the incoming side of calling; default on, so only an explicit false disables inbound.
  def inbound_calls_enabled?
    provider_config['inbound_calls_enabled'] != false
  end

  # Whether this inbox can do WhatsApp calling at all. Meta's Calling API is
  # reachable by any whatsapp_cloud inbox, so 360dialog inboxes can't be toggled
  # on even though calling_enabled would persist.
  def voice_calling_supported?
    provider == 'whatsapp_cloud'
  end

  def provider_service
    case provider
    when 'whatsapp_cloud'
      Whatsapp::Providers::WhatsappCloudService.new(whatsapp_channel: self)
    when 'baileys'
      Whatsapp::Providers::WhatsappBaileysService.new(whatsapp_channel: self)
    when 'zapi'
      Whatsapp::Providers::WhatsappZapiService.new(whatsapp_channel: self)
    else
      Whatsapp::Providers::Whatsapp360DialogService.new(whatsapp_channel: self)
    end
  end

  def template_access_token
    return provider_config['api_key'] unless ChatwootApp.chatwoot_cloud? && provider_config['source'] == 'embedded_signup'

    business_management_token.presence || provider_config['api_key']
  end

  def serializable_hash(options = nil)
    super.except('business_management_token')
  end

  def use_internal_host?
    provider == 'baileys' && ENV.fetch('BAILEYS_PROVIDER_USE_INTERNAL_HOST_URL', false)
  end

  # Enables voice: turns calling on at Meta (idempotent), then re-registers webhooks
  # with the in-memory calling_enabled flag so the `calls` field is subscribed. The
  # flag is persisted only after registration succeeds, so a webhook failure can't
  # leave the inbox reporting voice_enabled? while the WABA isn't subscribed to calls.
  # Saved with validate: false to skip validate_provider_config's remote credential
  # re-check, which could spuriously fail and desync the flag from Meta.
  def enable_voice_calling!
    raise 'WhatsApp calling requires a whatsapp_cloud inbox' unless voice_calling_supported?
    raise 'WhatsApp calling requires the channel_voice feature' unless account.feature_enabled?('channel_voice')

    provider_service.update_calling_status('ENABLED')
    self.provider_config = provider_config.merge('calling_enabled' => true)
    webhook_setup_service.register_callback
    save!(validate: false)
  end

  # Disables voice: unsets calling_enabled (gates the call subsystem) and re-registers
  # webhooks, which drops `calls` from the subscription (best-effort, so a Meta outage
  # can't trap admins). Leaves Meta's WABA calling.status untouched.
  def disable_voice_calling!
    raise 'WhatsApp calling requires a whatsapp_cloud inbox' unless voice_calling_supported?

    self.provider_config = provider_config.merge('calling_enabled' => false)
    save!(validate: false)
    begin
      webhook_setup_service.register_callback
    rescue StandardError => e
      Rails.logger.warn "[WHATSAPP CALL] disable webhook re-subscribe failed: #{e.message}"
    end
  end

  # Whether the pending (unsaved) provider_config change drops the embedded_signup
  # source marker, i.e. this save is an embedded signup → manual setup transfer.
  def embedded_to_manual_transfer_pending?
    before, after = provider_config_change
    before&.dig('source') == 'embedded_signup' && after['source'] != 'embedded_signup'
  end

  def app_secret_pending?
    manual_cloud_setup? && provider_config['app_secret'].blank?
  end

  def mark_message_templates_updated
    # rubocop:disable Rails/SkipsModelValidations
    update_column(:message_templates_last_updated, Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  def update_provider_connection!(provider_connection)
    provider_connection ||= {} # deep_stringify_keys below requires a hash
    # Normalize to string keys to match the persisted jsonb (which always reads back as
    # strings) so an unchanged status is recognized as a no-op and skipped.
    normalized = provider_connection.deep_stringify_keys
    return if normalized == self.provider_connection

    previous_connection = self.provider_connection['connection']
    connection_changed = normalized['connection'] != previous_connection
    assign_attributes(provider_connection: normalized)
    # NOTE: Skip `validate_provider_config?` check.
    # The change goes to clients through a targeted `inbox.provider_connection_updated`
    # event, and most of these writes are frequent and say nothing a cached inbox list
    # needs (a new QR every few seconds while pairing, an error, the epoch), so
    # `Inbox.no_touching` keeps them from touching the inbox and invalidating the whole
    # account inbox cache. A change of `connection` itself is rare and is the one thing
    # that list shows: the inbox is touched for it, which moves the account's inbox key, so
    # a dashboard that missed the event loads the right state on its next revalidation
    # (reconnect or page load) instead of a dropped session as connected (#856).
    if connection_changed
      save!(validate: false)
    else
      Inbox.no_touching { save!(validate: false) }
    end
    broadcast_provider_connection_updated(previous_connection)
  end

  # Proactive (REST poll) / push update of just the reach-out lock. Unlike the connection.update
  # path this carries no lease epoch, so it merges into the existing provider_connection without
  # touching connection/epoch/qr/error and reuses update_provider_connection!'s no-op guard and
  # broadcast. The with_lock reloads under SELECT FOR UPDATE so a concurrent connection.update
  # can't be lost by merging onto a stale snapshot. Callers pass nil (404/fetch error) to skip.
  def update_reachout_time_lock!(reachout_time_lock)
    return if reachout_time_lock.nil?

    with_lock do
      update_provider_connection!(provider_connection.merge('reachout_time_lock' => reachout_time_lock.deep_stringify_keys))
    end
  end

  # Same contract as update_reachout_time_lock! for the new-chat message cap (quota). We persist
  # only the UI-relevant keys (dropping the volatile server_sent_timestamp) so the poll doesn't
  # re-broadcast every cycle when nothing meaningful changed.
  def update_new_chat_cap!(new_chat_cap)
    return if new_chat_cap.nil?

    normalized = new_chat_cap.to_h.deep_stringify_keys.slice(*NEW_CHAT_CAP_KEYS)
    with_lock do
      update_provider_connection!(provider_connection.merge('new_chat_cap' => normalized))
    end
  end

  def provider_connection_data
    data = provider_connection_agent_data
    data.merge!(provider_connection_admin_data) if Current.account_user&.administrator?
    data
  end

  # The half of the connection payload every agent receives, shared by the REST serializer
  # above and by the cable push for the same reason as the admin half below. None of it is
  # credential-sensitive, and each piece is something the conversation view has no other
  # way to learn:
  #   - a send stall: a timeout count, a duration, what the provider decided to do and until
  #     when; the agent is the one being told their reply went nowhere, and `connection`
  #     still reads 'open' throughout;
  #   - `rerouting`: the connector reconnecting on purpose (a proxy change). The error
  #     string is admin-only, so without it a deliberate reconnect and an outage read the
  #     same in an agent's view.
  def provider_connection_agent_data(connection = provider_connection)
    {
      connection: connection['connection'],
      reachout_time_lock: connection['reachout_time_lock'].presence,
      new_chat_cap: connection['new_chat_cap'].presence,
      send_stall: connection['send_stall'].presence,
      rerouting: connection['rerouting'].presence
    }.compact
  end

  # The admin-only half of the connection payload, shared by the REST serializer above and
  # by the cable push, so a field added to one cannot go missing from the other. The
  # argument is the snapshot being presented: on the push path that is the hash the event
  # carried, not whatever the record happens to hold by the time the listener runs.
  def provider_connection_admin_data(connection = provider_connection)
    { qr_data_url: connection['qr_data_url'], error: connection['error'] }
  end

  def toggle_typing_status(typing_status, conversation:)
    return unless provider_service.respond_to?(:toggle_typing_status)

    recipient_id = conversation.contact.identifier || conversation.contact.phone_number
    last_message = conversation.messages.last
    provider_service.toggle_typing_status(typing_status, last_message: last_message, recipient_id: recipient_id)
  end

  def update_presence(status)
    return unless provider_service.respond_to?(:update_presence)

    provider_service.update_presence(status)
  end

  def read_messages(messages, conversation:)
    return unless provider_service.respond_to?(:read_messages)
    # NOTE: This is the default behavior, so `mark_as_read` being `nil` is the same as `true`.
    return if provider_config&.dig('mark_as_read') == false

    recipient_id = if provider == 'zapi'
                     conversation.contact.phone_number
                   else
                     conversation.contact.identifier || conversation.contact.phone_number
                   end

    # Marked before the send: the provider echoes this receipt back as an inbound one, and
    # the handlers that read it must not take it for a device of this account opening the
    # chat. See Whatsapp::SelfReadReceipts.
    Whatsapp::SelfReadReceipts.record(conversation, messages) if marker_read_back?
    provider_service.read_messages(messages, recipient_id: recipient_id)
  end

  def unread_conversation(conversation)
    return unless provider_service.respond_to?(:unread_message)

    # NOTE: For the Baileys provider, the last message is required even if it is an outgoing message.
    last_message = conversation.messages.last
    provider_service.unread_message(conversation.contact.phone_number, last_message) if last_message
  end

  def disconnect_channel_provider
    provider_service.disconnect_channel_provider
  rescue StandardError => e
    # Two callers, opposite needs. A destroy must not be blocked by a provider that will
    # not let go, so there the failure is logged and swallowed. An explicit disconnect is
    # an operator waiting for an answer: reporting a session closed while it is still
    # live leaves them with a connected number, a dashboard that disagrees, and no reason
    # to try again — and for a send stall it also clears the warning that was the only
    # thing telling anyone the inbox was mute. @session_teardown is set by the prepended
    # before_destroy callback, so it means exactly "we are being destroyed".
    raise unless @session_teardown

    Rails.logger.error "Failed to disconnect channel provider: #{e.message}"
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/BlockLength
  def convert_provider!(new_provider:, new_provider_config:)
    # Serialize concurrent conversions of the same inbox. Without the lock,
    # two admin requests could both pass pre-validation, race the disconnect
    # and save, and leave webhooks/templates mismatched with the persisted
    # provider. `with_lock` issues SELECT FOR UPDATE and wraps the block in
    # a transaction; the loser waits until the winner commits.
    with_lock do
      previous_provider = provider
      previous_provider_config = provider_config.deep_dup
      normalized_new_config = new_provider_config || {}

      if new_provider == previous_provider
        errors.add(:provider, 'must be different from the current provider')
        raise ActiveRecord::RecordInvalid, self
      end

      # Pre-validate the new config without persisting, so we never terminate
      # the current provider session for a known-bad target config.
      assign_attributes(provider: new_provider, provider_config: normalized_new_config)
      unless valid?
        assign_attributes(provider: previous_provider, provider_config: previous_provider_config)
        raise ActiveRecord::RecordInvalid, self
      end
      # Snapshot provider_config AFTER valid? so we keep any fields populated
      # by before_validation callbacks (e.g. ensure_webhook_verify_token). The
      # final persist uses save!(validate: false), so we must not rely on a
      # second validation pass to replay those callbacks.
      validated_new_config = provider_config.deep_dup

      # Validation passed. Restore the old state briefly so the disconnect
      # call talks to the correct (old) endpoint, then reapply and persist
      # the new state. We call the service directly so a failed disconnect
      # propagates and aborts the conversion instead of silently leaving the
      # old session alive while the inbox points at the new provider.
      assign_attributes(provider: previous_provider, provider_config: previous_provider_config)
      # When converting away from whatsapp_cloud, mirror the destroy-time
      # cleanup so the Meta webhook subscription is torn down (embedded_signup
      # source); manual-setup channels follow the same no-op behavior as on
      # destruction. A teardown failure on a best-effort cleanup should not
      # abort the swap.
      if previous_provider == 'whatsapp_cloud'
        begin
          teardown_webhooks
        rescue StandardError => e
          Rails.logger.error "[WHATSAPP] Pre-conversion webhook teardown failed: #{e.message}"
        ensure
          # Reset the destroy-time guard so a later destroy! or subsequent
          # conversion on the same instance doesn't skip webhook removal.
          @webhook_teardown_initiated = false
        end
      end
      disconnect_previous_provider(previous_provider)

      assign_attributes(
        provider: new_provider,
        provider_config: validated_new_config,
        provider_connection: {},
        message_templates: {},
        message_templates_last_updated: nil
      )
      # Skip revalidation: the pre-flight valid? above is authoritative. A
      # second validate_provider_config? call here would re-hit the external
      # API and a transient failure could roll back the transaction after we
      # already disconnected the old session.
      save!(validate: false)

      setup_webhooks if should_auto_setup_webhooks?

      begin
        sync_templates
      rescue StandardError => e
        # Some provider sync_templates implementations stamp
        # `message_templates_last_updated` before the remote fetch. If the
        # fetch blows up, reset both columns so the inbox doesn't look
        # synced with zero templates and the scheduler will retry.
        update_columns(message_templates: {}, message_templates_last_updated: nil) # rubocop:disable Rails/SkipsModelValidations
        Rails.logger.error "[WHATSAPP] Post-conversion template sync failed: #{e.message}"
      end
    end

    self
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/BlockLength

  def received_messages(messages, conversation)
    return unless provider_service.respond_to?(:received_messages)

    recipient_id = conversation.contact.identifier || conversation.contact.phone_number
    provider_service.received_messages(recipient_id, messages)
  end

  def on_whatsapp(phone_number, deadline: :provider)
    return unless provider_service.respond_to?(:on_whatsapp)

    provider_service.on_whatsapp(phone_number, deadline: deadline)
  end

  def delete_message(message, conversation:)
    return unless provider_service.respond_to?(:delete_message)

    recipient_id = if provider == 'zapi'
                     conversation.contact.phone_number.presence || conversation.contact.identifier
                   else
                     conversation.contact.identifier || conversation.contact.phone_number
                   end
    return if recipient_id.blank?

    provider_service.delete_message(recipient_id, message)
  end

  def edit_message(message, new_content, conversation:)
    return unless provider_service.respond_to?(:edit_message)

    recipient_id = conversation.contact.identifier || conversation.contact.phone_number
    provider_service.edit_message(recipient_id, message, new_content)
  end

  def sync_group(conversation, soft: false)
    return unless provider_service.respond_to?(:sync_group)

    provider_service.sync_group(conversation, soft: soft)
  end

  # Only Baileys and the session providers manage groups. Every inbox payload asks, and building any
  # other provider's service for a constant no is work the payload does not need.
  def allow_group_creation?
    return false unless provider == 'baileys' || session_provider?

    provider_service.respond_to?(:allow_group_creation?) && provider_service.allow_group_creation?
  end

  delegate :setup_channel_provider, to: :provider_service
  delegate :import_session, to: :provider_service
  delegate :reassert_desired_state, to: :provider_service
  delegate :presence_subscribe, to: :provider_service
  delegate :send_message, to: :provider_service
  delegate :send_template, to: :provider_service
  delegate :sync_templates, to: :provider_service
  delegate :media_url, to: :provider_service
  delegate :api_headers, to: :provider_service
  delegate :create_group, to: :provider_service
  delegate :update_group_subject, to: :provider_service
  delegate :update_group_description, to: :provider_service
  delegate :update_group_picture, to: :provider_service
  delegate :update_group_participants, to: :provider_service
  delegate :group_invite_code, to: :provider_service
  delegate :revoke_group_invite, to: :provider_service
  delegate :group_join_requests, to: :provider_service
  delegate :handle_group_join_requests, to: :provider_service
  delegate :group_leave, to: :provider_service
  delegate :group_setting_update, to: :provider_service
  delegate :group_join_approval_mode, to: :provider_service
  delegate :group_member_add_mode, to: :provider_service

  def send_contact_info_request(identifier, message)
    raise NotImplementedError, 'Contact information requests require a WhatsApp Cloud provider' unless provider == 'whatsapp_cloud'

    Whatsapp::Providers::WhatsappCloudContactInfoRequestService.perform(self, identifier, message)
  end

  def setup_webhooks(is_coexistence: nil)
    perform_webhook_setup(is_coexistence: is_coexistence)
  rescue StandardError => e
    Rails.logger.error "[WHATSAPP] Webhook setup failed: #{e.message}"
    return unless credentials_refused?(e)

    Rails.logger.error("[WHATSAPP] Asking for reauthorization on channel #{id}: #{reauthorization_reason(e)}")
    prompt_reauthorization!
  end

  private

  # Ends the old provider's session before a conversion, and lets a failure abort it: a
  # provider that is configured and does not answer may still hold a live session, and
  # converting over it would leave two connections on one account. An installation with no
  # provider configured at all has no session it could end, so there the conversion goes on
  # and says so, instead of refusing forever and leaving the inbox stuck (#745).
  def disconnect_previous_provider(previous_provider)
    return unless provider_service.respond_to?(:disconnect_channel_provider)

    if provider_service.respond_to?(:provider_configured?) && !provider_service.provider_configured?
      Rails.logger.warn "[WHATSAPP] Converting inbox #{inbox&.id}: no #{previous_provider} provider is configured, " \
                        'so its old session could not be ended'
      return
    end

    provider_service.disconnect_channel_provider
  end

  # `prompt_reauthorization!` is not a log line: it writes the marker, runs the handler that emails
  # the operator, invalidates the inbox cache and fires the event, and `Webhooks::WhatsappEventsJob`
  # discards every inbound webhook while the marker stands. Nothing clears it but a human. So it
  # takes an answer that says the credentials are the problem, and a Meta that accepts the
  # connection and stays quiet is not one: measured on `main`, three ceiling-capped calls in a row
  # marked a perfectly good channel in 30s.
  #
  # `ArgumentError` is the opposite case rather than an exception to the rule. It is what
  # `Whatsapp::WebhookSetupService` raises when the access token or the WABA id is blank, and a
  # credential that is not there is as definite an answer as one Meta rejected.
  #
  # The walk down `cause` is what makes this survive the layers in between: the setup service
  # re-raises with a prefix so the operator can see which step failed, and Ruby keeps the original
  # underneath. Asking only the outermost error would read every one of those as silence.
  def credentials_refused?(error)
    # Read at the top and not down the chain, unlike Meta's answer: the setup service raises this one
    # from `perform` and nothing wraps it, while an `ArgumentError` coming from inside the Graph call
    # path would be about something else entirely and has no business speaking for the credentials.
    return true if error.is_a?(ArgumentError)

    while error
      return true if error.is_a?(Whatsapp::ApiError) && error.authorization_error?

      error = error.cause
    end

    false
  end

  # Named by what happened, not by "Meta refused": the blank-credential branch reaches this line
  # without a single call having left, and a log that says Meta spoke is the same trade this class
  # of bug is about. The channel id rather than the inbox's, because the `after_commit on: :create`
  # path runs before the inbox exists and was printing "for inbox ;".
  def reauthorization_reason(error)
    return 'the setup could not run without a credential' if error.is_a?(ArgumentError)

    'Meta answered that the credentials are the problem'
  end

  # Whether anything on the way in will read the marker back. Written by exactly the two
  # inbound paths that can mistake our own receipt for a device read: the canonical session
  # handler, which covers every session provider, and the legacy Baileys one.
  #
  # Not `session_family?`, though it is nearly the same set. That asks "is this a paired
  # phone", and the echo does need one -- a business API has no second device to hear it
  # from. But Z-API is a paired phone whose status callback only moves a message's status
  # and never `agent_last_seen_at`, so it has nothing to be misled about, and a marker
  # written for it is a key per message that expires without ever being read.
  def marker_read_back?
    session_provider? || provider == 'baileys'
  end

  # Pushes the connection status to the account's agents over the websocket without
  # going through the full dispatcher, which would always enqueue an EventDispatcherJob
  # (wasteful for such a high-frequency event). Sync-only keeps it cheap. The previous
  # `connection` travels with it so AgentBotListener can tell the rare change of state from
  # the QR/error/epoch churn without reading anything.
  def broadcast_provider_connection_updated(previous_connection)
    return if inbox.blank?

    Rails.configuration.dispatcher.sync_dispatcher.dispatch(
      Events::Types::INBOX_PROVIDER_CONNECTION_UPDATED, Time.zone.now,
      inbox: inbox, provider_connection: provider_connection, previous_connection: previous_connection
    )
  end

  # The stored token wins over whatever came in, because provider_config is permitted wholesale
  # by the inbox API and an update is a plain replace of the column: one that leaves the token
  # out would otherwise mint a new one while the provider keeps posting the old one. A provider
  # change (creation included) is the one write that starts over.
  # Z-API's token is never minted here: it is born with the URL that carries it, in
  # Whatsapp::Providers::WhatsappZapiService#register_webhooks. So is the record of which Z-API
  # instance took that URL, which closes the old one for the inbox and is kept the same way.
  def ensure_webhook_verify_token
    return unless provider.in?(%w[whatsapp_cloud baileys zapi])

    stored = provider_changed? ? {} : stored_provider_config
    token = stored['webhook_verify_token'].presence || provider_config['webhook_verify_token'].presence
    return keep_zapi_webhook_url(token, stored) if provider == 'zapi'

    provider_config['webhook_verify_token'] = token || SecureRandom.hex(16)
  end

  # Kept like the token, for the same wholesale replace: an update that left the secret out
  # would otherwise turn an inbox whose webhooks are verified back into one that takes them
  # unsigned. Replacing it is fine; removing it is not something an update can do. The one
  # exception is a move to embedded signup, which runs on the installation's app and is
  # verified with WHATSAPP_APP_SECRET: the secret left from the manual setup belongs to
  # another app, and would be checked against a token that app did not issue.
  def keep_app_secret
    return if provider_changed?

    stored = stored_provider_config
    return provider_config.delete('app_secret') if moving_to_embedded_signup?(stored)
    return if provider_config['app_secret'].present? || stored['app_secret'].blank?

    provider_config['app_secret'] = stored['app_secret']
  end

  def moving_to_embedded_signup?(stored)
    provider_config['source'] == 'embedded_signup' && stored['source'] != 'embedded_signup'
  end

  # The row as it is now, locked until this save commits, rather than provider_config_was: a record
  # loaded before a Z-API token was reserved would otherwise write the config back without it.
  def stored_provider_config
    return {} if new_record?

    self.class.lock.where(id: id).pick(:provider_config).to_h
  end

  def keep_zapi_webhook_url(token, stored)
    provider_config['webhook_verify_token'] = token if token
    provider_config['webhook_url_confirmed_for'] = stored['webhook_url_confirmed_for'] if stored['webhook_url_confirmed_for']
    if stored['previous_webhook_verify_token']
      provider_config['previous_webhook_verify_token'] = stored['previous_webhook_verify_token']
    else
      provider_config.delete('previous_webhook_verify_token')
    end
  end

  # Meta signs every Cloud webhook with the secret of the app that issued the token. Embedded
  # signup runs on the installation's own app, whose secret is WHATSAPP_APP_SECRET; any other
  # Cloud inbox brings its app's, or its webhooks cannot be told apart from a forged one. Asked
  # for when an inbox becomes a manual Cloud inbox (created, converted or moved off embedded
  # signup), so the inboxes that already exist keep working until their operator adds it.
  def app_secret_required?
    return false unless provider == 'whatsapp_cloud' && provider_config['source'] != 'embedded_signup'

    new_record? || provider_changed? || provider_config_was.to_h['source'] == 'embedded_signup'
  end

  def validate_app_secret
    errors.add(:provider_config, 'App secret is required') if provider_config['app_secret'].blank?
  end

  # A check that could not reach a verdict is neither a refusal nor a broken application, so it gets a
  # sentence of its own. Only that one class is rescued: a defect of ours inside the check escapes as
  # itself, because telling the operator to try again is no use when the thing to fix is the code.
  def ensure_webhook_token
    return unless provider == 'default'

    # Derived for existing channels so concurrent saves register the same token with 360dialog.
    provider_config['webhook_token'] ||= if new_record?
                                           SecureRandom.hex(16)
                                         else
                                           OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "whatsapp_webhook_token:#{id}")
                                         end
  end

  def validate_provider_config
    return if errors.any?

    errors.add(:provider_config, 'Invalid Credentials') unless provider_service.validate_provider_config?
  rescue Whatsapp::CredentialCheck::Unavailable => e
    Rails.logger.warn("[WHATSAPP] Credential check could not be completed for #{provider} channel #{id || 'new'}: #{e.message}")
    errors.add(:provider_config, I18n.t('errors.inboxes.channel.credential_check_unavailable'))
  end

  def manual_cloud_setup?
    provider == 'whatsapp_cloud' && provider_config['source'] != 'embedded_signup'
  end

  # Logs only the embedded signup → manual migration (the save drops the
  # embedded_signup source marker), so credential rotations on inboxes that are
  # already manual stay silent.
  def log_credentials_transfer
    before, after = saved_change_to_provider_config
    return unless before&.dig('source') == 'embedded_signup' && after['source'] != 'embedded_signup'

    Rails.logger.info("[WHATSAPP_EMBEDDED_TO_MANUAL] success account_id=#{account_id} channel_id=#{id}")
  end

  def perform_webhook_setup(is_coexistence: nil)
    webhook_setup_service(is_coexistence: is_coexistence).perform
  end

  def webhook_setup_service(is_coexistence: nil)
    Whatsapp::WebhookSetupService.new(self, provider_config['business_account_id'], provider_config['api_key'], is_coexistence: is_coexistence)
  end

  def teardown_webhooks
    # NOTE: Guard against double execution during destruction due to the
    # `has_one :inbox, dependent: :destroy` relationship which will trigger this callback circularly
    return if @webhook_teardown_initiated

    @webhook_teardown_initiated = true
    Whatsapp::WebhookTeardownService.new(self).perform
  end

  def should_auto_setup_webhooks?
    # Embedded signup and Manual V2 run webhook setup explicitly so their API
    # responses can reflect the real result instead of swallowing callback errors.
    explicitly_configured_sources = %w[embedded_signup manual_setup_v2]
    provider == 'whatsapp_cloud' && explicitly_configured_sources.exclude?(provider_config['source'])
  end
end

Channel::Whatsapp.prepend_mod_with('Channel::Whatsapp')
