# Sends one CRM revenue event (won/lost/move) to the Meta Conversions API for CTWA
# attribution. Enqueued by Crm::MetaCapiListener with IDS ONLY.
#
# Flow: reload card -> claim a ledger row atomically by event_id (the unique index is the
# lock) -> require ctwa_clid + credentials (skip + record when absent) -> resolve the
# canonical Meta event_name (nil => nothing to send) -> POST -> record the outcome.
#
# Idempotency: event_id is anchored on the activity id, so Sidekiq retries and duplicate
# activities reuse the same row. Because Meta does NOT dedup CAPI-BM server-side, the
# unique event_id row IS the only guard against double-posting — we claim it (save pending)
# before the POST and short-circuit if another worker already owns it.
#
# SECURITY: the Meta access token must NEVER reach a log or exception. It is only passed to
# the client (which sends it in an Authorization header and swallows its own errors
# sanitized); we never interpolate it, and the outer rescue re-raises with cause: nil so
# Sidekiq's backtrace cannot carry the original (possibly token-bearing) exception.
class Crm::MetaCapi::DispatchJob < ApplicationJob
  queue_as :low

  class DispatchError < StandardError; end

  def perform(account_id, card_id, activity_id, event_type, source: 'live')
    card = Crm::Card.find_by(id: card_id, account_id: account_id)
    return if card.blank?

    event_id = build_event_id(card_id, event_type, activity_id)
    row = claim_row(event_id, card, event_type, source)
    return if row.nil?

    deliver(row, card, event_id, event_type)
  rescue DispatchError
    raise
  rescue StandardError => e
    Rails.logger.error("Crm::MetaCapi::DispatchJob error card=#{card_id} event=#{event_type}: #{sanitize(e.message)}")
    raise DispatchError.new("Crm::MetaCapi::DispatchJob failed card=#{card_id} event=#{event_type}"), cause: nil
  end

  private

  # Atomically claim the ledger row. The unique index on event_id is the lock: the first
  # worker inserts a `pending` row; a concurrent worker hits RecordNotUnique and backs off
  # (nil). An already-accepted row short-circuits so we never re-post a delivered event.
  def claim_row(event_id, card, event_type, source)
    row = Crm::MetaConversionEvent.find_or_initialize_by(event_id: event_id)
    return nil if row.persisted? && row.accepted?

    assign_context(row, card, event_type, source)
    row.status = :pending
    row.save!
    row
  rescue ActiveRecord::RecordNotUnique
    nil
  end

  def deliver(row, card, event_id, event_type)
    ctwa_clid = resolve_ctwa_clid(card)
    return skip(row, 'missing_ctwa_clid') if ctwa_clid.blank?

    credentials = resolve_credentials(card)
    return skip(row, 'missing_credentials') if credentials[:access_token].blank? || credentials[:dataset_id].blank?

    event_name = Crm::MetaCapi::PayloadBuilder.canonical_event_name(event_type: event_type, stage_type: row.funnel_stage_type)
    return skip(row, 'no_meta_event') if event_name.blank?

    row.update!(ctwa_clid: ctwa_clid, dataset_id: credentials[:dataset_id])
    payload = Crm::MetaCapi::PayloadBuilder.build(
      card: card, event_name: event_name, event_type: event_type, event_id: event_id,
      attribution: { ctwa_clid: ctwa_clid, waba_id: credentials[:waba_id] }
    )
    response = Meta::ConversionsApiClient.new(access_token: credentials[:access_token], dataset_id: credentials[:dataset_id]).post_events([payload])
    record_result(row, response)
  end

  # Persists the delivery outcome. A rejected event raises (sanitized, cause-less) so
  # Sidekiq retries with its default backoff; the ledger row keeps the last http_code.
  def record_result(row, response)
    if response.ok
      row.update!(status: :accepted, http_code: response.http_code, sent_at: Time.current, error_message: nil)
    else
      row.update!(status: :error, http_code: response.http_code, error_message: sanitize(response.error))
      raise DispatchError.new("Meta CAPI rejected event=#{row.event_id} http=#{response.http_code}"), cause: nil
    end
  end

  # Ledger scaffolding shared by every terminal state (accepted/skipped/error).
  def assign_context(row, card, event_type, source)
    row.assign_attributes(
      account_id: card.account_id,
      card_id: card.id,
      pipeline_id: card.pipeline_id,
      event_type: event_type,
      source: source,
      funnel_stage_type: card.stage&.metadata&.dig('funnel_stage_type'),
      value_cents: card.value_cents,
      currency: card.currency
    )
  end

  def skip(row, reason)
    row.update!(status: :skipped, error_message: reason)
    nil
  end

  # Stable per-activity id: also the Meta event_id. activity_id is unique per logical
  # transition and never changes on retry, so the ledger row is reused deterministically.
  def build_event_id(card_id, event_type, activity_id)
    "crm-#{card_id}-#{event_type}-#{activity_id}"
  end

  # CTWA click id lives on the linked conversation's campaign attribution
  # (Ctwa::CampaignBuilder writes additional_attributes['campaign']['ctwa_clid']).
  def resolve_ctwa_clid(card)
    conversation = card.primary_conversation
    return if conversation.blank?

    campaign = conversation.additional_attributes['campaign']
    campaign.is_a?(Hash) ? campaign['ctwa_clid'].presence : nil
  end

  # Reuses the WhatsApp channel credential (no new secret storage): the card's inbox is the
  # CTWA entry point, so its channel holds both the token and the WABA id. dataset_id is the
  # per-pipeline destination configured in the funnel editor (metadata['meta_sync']).
  def resolve_credentials(card)
    inbox = card.primary_conversation&.inbox || card.inbox
    channel = inbox&.channel
    config = channel.respond_to?(:provider_config) ? channel.provider_config.to_h : {}
    {
      access_token: config['api_key'].presence,
      waba_id: config['business_account_id'].presence,
      dataset_id: card.pipeline&.metadata&.dig('meta_sync', 'dataset_id').presence
    }
  end

  def sanitize(text)
    return if text.blank?

    text.to_s.gsub(Meta::ConversionsApiClient::SENSITIVE_PATTERN, '<REDACTED>')
  end
end
