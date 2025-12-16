# == Schema Information
#
# Table name: ottiv_calendar_items
#
#  id              :bigint           not null, primary key
#  item_type       :integer          default(0), not null
#  title           :string           not null
#  description     :text
#  start_at        :datetime         not null
#  end_at          :datetime
#  location        :string
#  status          :integer          default(0), not null
#  user_id         :bigint           not null
#  account_id      :bigint           not null
#  conversation_id :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class OttivCalendarItem < ApplicationRecord
  belongs_to :user
  belongs_to :account
  belongs_to :conversation, optional: true
  has_many :ottiv_reminders, foreign_key: :ottiv_calendar_item_id, dependent: :destroy

  # Relacionamentos para contatos (referência, sem notificação)
  has_many :ottiv_calendar_item_contacts, dependent: :destroy
  has_many :contacts, through: :ottiv_calendar_item_contacts

  # Relacionamentos para participantes (usuários notificados)
  # Nota: O criador sempre é incluído automaticamente como participante
  has_many :ottiv_calendar_item_participants, dependent: :destroy
  has_many :participants, through: :ottiv_calendar_item_participants, source: :user

  enum item_type: { reminder: 0, event: 1 }  # Removido 'schedule' (redundante)
  enum status: { active: 0, cancelled: 1, done: 2 }

  validates :title, presence: true, length: { maximum: 255 }
  validates :start_at, presence: true
  validates :user_id, presence: true
  validates :account_id, presence: true
  validate :end_at_after_start_at, if: :end_at?
  validate :start_at_not_in_past, on: :create

  scope :active, -> { where(status: :active) }
  scope :upcoming, -> { where('start_at >= ?', Time.current).order(start_at: :asc) }
  scope :by_date_range, ->(start_date, end_date) { where(start_at: start_date..end_date) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_conversation, ->(conversation_id) { where(conversation_id: conversation_id) }

  # Status management methods
  def complete!
    update!(status: :done)
  end

  def cancel!
    update!(status: :cancelled)
  end

  def past?
    target_date = end_at || start_at
    target_date < Time.current
  end

  def self.auto_complete_past_items
    # Auto-complete items that are past their end time (or start time if no end time)
    # Give 1 hour grace period before auto-completing
    active.where('end_at < ? OR (end_at IS NULL AND start_at < ?)', 
                 1.hour.ago, 1.hour.ago)
          .find_each(&:complete!)
  end

  private

  def end_at_after_start_at
    return unless end_at && start_at

    errors.add(:end_at, 'must be after start_at') if end_at <= start_at
  end

  def start_at_not_in_past
    return unless start_at

    # Permitir margem de 1 minuto para compensar latência de rede e diferenças de fuso horário
    errors.add(:start_at, 'cannot be in the past') if start_at < 1.minute.ago
  end
end

