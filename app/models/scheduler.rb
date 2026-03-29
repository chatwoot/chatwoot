class Scheduler < ApplicationRecord
  MESSAGE_TYPES = %w[d1_reminder visit_guidance happy_call_same_day happy_call_2weeks].freeze

  belongs_to :account
  belongs_to :inbox
  has_many :scheduled_messages, dependent: :destroy_async

  validates :account_id, presence: true
  validates :inbox_id, presence: true
  validates :title, presence: true
  validates :message_type, presence: true, inclusion: { in: MESSAGE_TYPES }
  validates :message_type, uniqueness: { scope: :account_id }
  validate :inbox_must_be_whatsapp
  validate :inbox_must_belong_to_account

  enum status: { active: 0, paused: 1 }

  after_commit :set_display_id, unless: :display_id?

  scope :enabled, -> { where(status: :active) }

  private

  def set_display_id
    reload
  end

  def inbox_must_be_whatsapp
    return unless inbox

    errors.add(:inbox, 'must be a WhatsApp inbox') unless inbox.inbox_type == 'Whatsapp'
  end

  def inbox_must_belong_to_account
    return unless inbox

    errors.add(:inbox_id, 'must belong to the same account') unless inbox.account_id == account_id
  end

  trigger.before(:insert).for_each(:row) do
    "NEW.display_id := nextval('scheduler_dpid_seq_' || NEW.account_id);"
  end
end
