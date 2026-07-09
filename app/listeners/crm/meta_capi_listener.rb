# Bridges CRM card lifecycle events onto the Meta Conversions API (CTWA revenue
# sync). Mirrors WebhookListener's crm_card_* handlers: the Emitter dispatches IDS
# ONLY (account_id, card_id, activity_id), so we reload the card by id here.
#
# Only the three revenue-relevant transitions are wired: won/lost (RESULT axis) and
# moved (STAGE axis). Each checks the card's pipeline meta_sync config and enqueues
# Crm::MetaCapi::DispatchJob with ids only (never AR objects) when the event is
# enabled. The pipeline/meta_sync gate is a cheap early-return that keeps the queue
# clean on accounts that never enabled the sync.
class Crm::MetaCapiListener < BaseListener
  def crm_card_won(event)
    enqueue(event, 'won')
  end

  def crm_card_lost(event)
    enqueue(event, 'lost')
  end

  def crm_card_moved(event)
    enqueue(event, 'moved')
  end

  private

  def enqueue(event, capi_event)
    account_id = event.data[:account_id]
    card_id = event.data[:card_id]
    return unless meta_sync_enabled?(account_id, card_id, capi_event)

    Crm::MetaCapi::DispatchJob.perform_later(account_id, card_id, event.data[:activity_id], capi_event)
  end

  # Reads crm_pipelines.metadata['meta_sync'] (jsonb): { enabled: bool,
  # events: { 'won' => bool, 'lost' => bool, 'moved' => bool }, dataset_id: '...' }.
  # Returns false unless the sync is on AND this specific event is subscribed.
  def meta_sync_enabled?(account_id, card_id, capi_event)
    card = Crm::Card.find_by(id: card_id, account_id: account_id)
    return false if card.blank?

    meta_sync = card.pipeline.metadata['meta_sync']
    return false if meta_sync.blank?

    meta_sync['enabled'].present? && meta_sync.dig('events', capi_event).present?
  end
end
