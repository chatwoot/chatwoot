module Whatsapp::BaileysHandlers::ConnectionUpdate
  include Whatsapp::BaileysHandlers::Helpers

  private

  def process_connection_update
    data = processed_params[:data]

    inbox.channel.with_lock do
      if stale_connection_event?(data)
        Rails.logger.warn(
          "Baileys stale connection.update discarded: epoch #{data[:epoch]} < #{inbox.channel.provider_connection['epoch']}"
        )
        next
      end

      inbox.channel.update_provider_connection!(provider_connection_payload(data))
      Rails.logger.error "Baileys connection error: #{data[:error]}" if data[:error].present?
    end

    end_backfill
  end

  # A history request travels to the phone through the session, so one that ends takes any
  # outstanding request with it. Without this the window a button press opened would still
  # be standing at the next pairing, and the dump the phone offers unprompted would be
  # filed as if somebody had asked for it. Read off the record rather than off the event,
  # because the payload can be rewritten on the way in.
  def end_backfill
    return if inbox.channel.provider_connection.to_h['connection'] == 'open'

    Whatsapp::Session::HistoryBackfill.close!(inbox.channel)
  end

  # NOTE: `connection` values
  #   - `close`: Never opened, or closed and no longer able to send/receive messages
  #   - `connecting`: In the process of connecting, expecting QR code to be read
  #   - `reconnecting`: Connection has been established, but not open (i.e. device is being linked for the first time, or Baileys server restart)
  #   - `open`: Open and ready to send/receive messages
  def provider_connection_payload(data)
    stall = send_stall_payload(data)
    {
      connection: data[:connection] || inbox.channel.provider_connection['connection'],
      qr_data_url: data[:qrDataUrl] || nil,
      error: connection_error(data, stall),
      quarantine: quarantine_payload(data),
      send_stall: stall,
      reachout_time_lock: reachout_time_lock_payload(data),
      # new_chat_cap never rides a connection.update (it arrives via message-capping.update / the
      # poll). update_provider_connection! replaces provider_connection wholesale, so without
      # carrying it forward here every connection.update would wipe the cap and flicker the banner
      # off until the next cap push/poll. Preserve the existing value; .compact omits it when unset.
      new_chat_cap: inbox.channel.provider_connection['new_chat_cap'],
      epoch: data[:epoch]
    }.compact
  end

  # The human-readable half of the warning, and the half that survives serialization for a
  # non-admin: provider_connection_data gives every agent `connection`, and only an admin
  # also gets error and send_stall. Preserving the structured detail without the string
  # would preserve nothing most viewers can read, so the two share a fate.
  #
  # Re-derived from the stall rather than copied from the stored error: copying would
  # resurrect whatever unrelated error happened to be stored last.
  def connection_error(data, stall)
    return I18n.t("errors.inboxes.channel.provider_connection.#{data[:error]}", default: data[:error].to_s.humanize) if data[:error]
    return I18n.t('errors.inboxes.channel.provider_connection.send_stall_detected') if stall.present?

    nil
  end

  # Rides only the send_stall_detected webhook: the connection is receiving and answering
  # health checks while every send times out. Worth surfacing on its own rather than as a
  # bare error string, because "action" is what tells an operator whether the provider
  # already recreated the socket or is holding off until `until` — and holding off is when
  # a human has to step in, which is why it is serialized to admins rather than kept for
  # support (quarantine, by contrast, still is).
  #
  # Unlike quarantine, this does NOT share the error's lifecycle. The provider reports a
  # stall once per episode, so an unrelated update in the meantime (a standalone
  # reachoutTimeLock push carries no sendStall) would clear the warning for good while the
  # connection is still mute — and nothing would ever say it again. So it is preserved,
  # and cleared only by the one event that actually means recovery: the connection
  # reaching `open` with nothing wrong, which is a NEW socket and therefore a new keystore
  # mutex, whether the provider restarted it or WhatsApp dropped it.
  def send_stall_payload(data)
    raw = data[:sendStall]
    if raw.blank?
      return nil if data[:connection] == 'open' && data[:error].blank?

      return inbox.channel.provider_connection['send_stall']
    end

    {
      consecutive_timeouts: raw[:consecutiveTimeouts],
      stalled_for_ms: raw[:stalledForMs],
      action: raw[:action],
      until: raw[:until]
    }.compact
  end

  # Rides only the reconnect_loop_detected webhook (baileys-api quarantines a phone after a
  # full failed reconnect cycle and reports how many cycles failed and when it will retry).
  # Shares the error's lifecycle on purpose: any later connection.update without it (e.g. the
  # next retry cycle's "reconnecting") clears it together with the error, so the UI never
  # shows a stale "retrying at ..." for a phone that already reconnected.
  def quarantine_payload(data)
    raw = data[:quarantine]
    return nil if raw.blank?

    {
      strikes: raw[:strikes],
      until: raw[:until]
    }.compact
  end

  # Reach-out time-lock is NOT echoed on every connection.update (the provider debounces it
  # ~60s and may push it standalone, without a `connection` value). So, unlike qr_data_url, a
  # connection-only event must PRESERVE the existing lock rather than reset it. When the
  # provider DOES send reachoutTimeLock (including isActive:false to lift the restriction), we
  # persist it verbatim — isActive:false is a real "cleared" state the UI relies on to drop the
  # banner. Returns nil only when nothing was ever set, so the outer .compact omits the key.
  def reachout_time_lock_payload(data)
    raw = data[:reachoutTimeLock]
    return inbox.channel.provider_connection['reachout_time_lock'] if raw.blank?

    {
      is_active: raw[:isActive] || false,
      time_enforcement_ends: raw[:timeEnforcementEnds],
      enforcement_type: raw[:enforcementType]
    }.compact
  end

  # In a multi-instance baileys-api deployment, ownership of a phone number
  # moves between instances (failover, rebalance, rolling deploys). Each
  # connection.update carries the lease epoch of its sender; events from a
  # previous owner can arrive late (webhook retries) and must not overwrite
  # the current owner's state — last-writer-wins here would leave the inbox
  # stuck on a stale "reconnecting" while the connection is actually open.
  # Events without an epoch (older baileys-api versions) are always accepted.
  def stale_connection_event?(data)
    return false if data[:epoch].blank?

    last_epoch = inbox.channel.provider_connection['epoch']
    return false if last_epoch.blank?

    data[:epoch].to_i < last_epoch.to_i
  end
end
