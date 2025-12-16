# == Schema Information
#
# Table name: ottiv_scheduled_messages
#
#  id              :bigint           not null, primary key
#  title           :string
#  message_type    :integer          default(0), not null
#  content         :text
#  media_url       :string
#  audio_url       :string
#  quick_reply_id  :bigint
#  account_id      :bigint           not null
#  conversation_id :bigint
#  contact_id      :bigint
#  send_at         :datetime         not null
#  timezone        :string           default("UTC"), not null
#  recurrence      :integer          default(0), not null
#  status          :integer          default(0), not null
#  created_by      :bigint           not null
#  sent_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class OttivScheduledMessage < ApplicationRecord
  belongs_to :account
  belongs_to :conversation, optional: true
  belongs_to :contact, optional: true
  belongs_to :creator, class_name: 'User', foreign_key: :created_by
  has_many :ottiv_scheduled_message_occurrences, foreign_key: :ottiv_scheduled_message_id, dependent: :destroy

  enum message_type: { text: 0, media: 1, audio: 2, quick_reply: 3 }
  enum recurrence: {
    no_recurrence: 0,
    daily: 1,
    weekly: 2,
    biweekly: 3,
    monthly: 4,
    quarterly: 5,
    semiannual: 6,
    annual: 7
  }
  enum status: { scheduled: 0, sent: 1, cancelled: 2, failed: 3 }

  validates :send_at, presence: true
  validates :timezone, presence: true
  validates :account_id, presence: true
  validates :created_by, presence: true
  validates :message_type, presence: true
  validate :send_at_in_future, on: :create
  validate :conversation_required_for_scheduled_message

  scope :pending, -> { where(status: :scheduled).where('send_at <= ?', Time.current) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :upcoming, -> { where(status: :scheduled).where('send_at > ?', Time.current).order(send_at: :asc) }

  def mark_as_sent!
    update!(status: :sent, sent_at: Time.current)
  end

  def mark_as_failed!(error_msg = nil)
    update!(status: :failed)
    ottiv_scheduled_message_occurrences.create!(
      status: :failed,
      error_message: error_msg
    ) if error_msg.present?
  end

  def cancel!
    update!(status: :cancelled)
  end

  def has_recurrence?
    # Rails enums return symbols, not strings
    !no_recurrence?
  end

  private

  def send_at_in_future
    return unless send_at

    # Permitir margem de 1 minuto para compensar latência de rede e diferenças de fuso horário
    errors.add(:send_at, 'must be in the future') if send_at <= 1.minute.ago
  end

  def conversation_required_for_scheduled_message
    errors.add(:conversation_id, 'is required for scheduled messages') if conversation_id.blank?
  end
end

