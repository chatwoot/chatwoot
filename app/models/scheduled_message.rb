class ScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :scheduler
  belongs_to :contact, optional: true

  validates :external_id, presence: true
  validates :customer_phone, presence: true
  validates :message_type, presence: true
  validates :scheduled_at, presence: true
  validates :external_id, uniqueness: { scope: :message_type }

  scope :pending, -> { where(status: 'pending') }
  scope :due, -> { pending.where('scheduled_at <= ?', Time.current) }
  scope :for_dispatch, -> { due.includes(:scheduler, :contact).order(:scheduled_at) }

  def mark_sent!(whatsapp_message_id: nil)
    update!(status: 'sent', sent_at: Time.current, whatsapp_message_id: whatsapp_message_id)
  end

  def mark_failed!(error:)
    update!(status: 'failed', error_message: error.to_s.truncate(255))
  end

  def mark_skipped!(reason:)
    update!(status: 'skipped', error_message: reason.to_s.truncate(255))
  end
end
