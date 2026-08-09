class CampaignRecipient < ApplicationRecord
  belongs_to :account
  belongs_to :campaign
  belongs_to :contact
  belongs_to :inbox

  enum status: {
    queued: 0,
    skipped: 1,
    sent: 2,
    delivered: 3,
    read: 4,
    failed: 5
  }

  validates :contact_id, uniqueness: { scope: :campaign_id }
  validates :source_id, uniqueness: true, allow_blank: true

  def mark_sent!(source_id)
    update!(
      source_id: source_id,
      status: :sent,
      sent_at: Time.current,
      error_code: nil,
      error_title: nil,
      error_message: nil
    )
  end

  def mark_skipped!(message)
    update!(status: :skipped, error_message: message)
  end

  def mark_failed!(error = {})
    update!(
      status: :failed,
      failed_at: event_time(error[:timestamp]),
      error_code: error[:code],
      error_title: error[:title],
      error_message: error[:message]
    )
  end

  def update_from_whatsapp_status!(status)
    normalized_status = status[:status].to_s
    return unless %w[delivered read failed].include?(normalized_status)

    with_lock do
      if normalized_status == 'delivered' && read?
        update!(delivered_at: event_time(status[:timestamp])) if delivered_at.blank?
        next
      end

      next if status_downgrade?(normalized_status)
      next mark_failed!(whatsapp_error(status)) if normalized_status == 'failed'

      update!(
        status: normalized_status,
        "#{normalized_status}_at": event_time(status[:timestamp])
      )
    end
  end

  private

  def status_downgrade?(new_status)
    return delivered? || read? if new_status == 'failed'

    self.class.statuses[new_status] < self.class.statuses[status]
  end

  def whatsapp_error(status)
    error = status[:errors]&.first || {}
    {
      code: error[:code],
      title: error[:title],
      message: error[:error_user_msg].presence || error[:error_data]&.dig(:details).presence || error[:message].presence,
      timestamp: status[:timestamp]
    }
  end

  def event_time(timestamp)
    return Time.current if timestamp.blank?

    Time.zone.at(timestamp.to_i)
  end
end
