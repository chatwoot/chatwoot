# Builds one CAPI-BM event hash (an element of the `data` array) from a CRM card.
#
# Two axes drive the Meta event_name (see BE-0 notes): the RESULT axis (won/lost) maps
# to fixed native events, while funnel movements (create/move) carry the destination
# stage's configured funnel_stage_type. reopen/archive have no native CAPI-BM event and
# resolve to nil (caller must not send).
#
# event_id is supplied by the caller (the DispatchJob ledger key) so the value we send to
# Meta and the value we dedup on in crm_meta_conversion_events are ALWAYS the same string
# — the anchor is the activity id (stable across Sidekiq retries and stage changes), not a
# late-dereferenced card.stage_id. occurred_at is derived from the card (close instant for
# won/lost, stage-entry instant for movements) and doubles as event_time.
module Crm::MetaCapi::PayloadBuilder
  module_function

  ACTION_SOURCE = 'business_messaging'.freeze
  MESSAGING_CHANNEL = 'whatsapp'.freeze
  # Native Meta events for the result axis. 'lost' -> OrderCanceled is the closest
  # documented proxy (there is no native 'Lost'/'Perdido' event). Purchase carries value.
  RESULT_EVENT_NAMES = { 'won' => 'Purchase', 'lost' => 'OrderCanceled' }.freeze
  # The single movement token emitted by Crm::MetaCapiListener#crm_card_moved and the
  # meta_sync events config key. Must stay 'moved' (not 'move'/'create') across the stack.
  MOVEMENT_EVENT_TYPES = %w[moved].freeze
  # CAPI-BM accepts only Meta's STANDARD event names — a raw funnel token such as
  # 'negotiation' is treated as a custom event and rejected with error #270
  # (verified against production, 2026-07-09: Purchase accepted, raw tokens 400).
  # Map the internal stage classification to standard funnel events in depth order.
  FUNNEL_EVENT_NAMES = {
    'lead' => 'LeadSubmitted',
    'qualified' => 'QualifiedLead',
    'opportunity' => 'AddToCart',
    'negotiation' => 'InitiateCheckout'
  }.freeze

  # Canonical Meta event_name for a CRM lifecycle event, or nil when it must not be sent.
  def canonical_event_name(event_type:, stage_type:)
    return RESULT_EVENT_NAMES[event_type] if RESULT_EVENT_NAMES.key?(event_type)
    return FUNNEL_EVENT_NAMES[stage_type.to_s] if MOVEMENT_EVENT_TYPES.include?(event_type)

    nil
  end

  # attribution: { ctwa_clid:, waba_id: } — the CTWA click id (unhashed) and the WABA id,
  # both required by Meta to tie the event back to the ad click.
  def build(card:, event_name:, event_type:, event_id:, attribution:)
    {
      'event_name' => event_name,
      'event_time' => occurred_at(card, event_type).to_i,
      'event_id' => event_id,
      'action_source' => ACTION_SOURCE,
      'messaging_channel' => MESSAGING_CHANNEL,
      'user_data' => {
        'whatsapp_business_account_id' => attribution[:waba_id],
        'ctwa_clid' => attribution[:ctwa_clid]
      }.compact,
      'custom_data' => custom_data(card).presence
    }.compact
  end

  # The close decision drives won/lost timing; funnel movements use stage entry. Falls
  # back to the current time so event_time/event_id are always well-formed.
  def occurred_at(card, event_type)
    anchor = RESULT_EVENT_NAMES.key?(event_type) ? card.closed_at : card.entered_stage_at
    anchor || Time.current
  end

  # Value is sent in the card's currency (cents -> major units) only when present; a
  # zero-value funnel event carries neither value nor currency.
  def custom_data(card)
    data = {}
    if card.value_cents.to_i.positive?
      data['value'] = card.value_cents / 100.0
      data['currency'] = card.currency
    end
    data['order_id'] = card.external_id if card.external_id.present?
    data
  end
end
