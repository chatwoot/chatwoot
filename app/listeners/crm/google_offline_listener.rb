class Crm::GoogleOfflineListener < BaseListener
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

  def enqueue(event, conversion_event)
    account_id = event.data[:account_id]
    card_id = event.data[:card_id]
    return unless google_sync_enabled?(account_id, card_id, conversion_event)

    Crm::GoogleOffline::RecordJob.perform_later(account_id, card_id, event.data[:activity_id], conversion_event)
  end

  def google_sync_enabled?(account_id, card_id, conversion_event)
    card = Crm::Card.find_by(id: card_id, account_id: account_id)
    google_sync = card&.pipeline&.metadata&.dig('google_sync')

    google_sync.present? && google_sync['enabled'].present? && google_sync.dig('events', conversion_event).present?
  end
end
