class Department < ApplicationRecord
  include AccountCacheRevalidator

  belongs_to :account
  has_many :queues, dependent: :destroy_async
  has_many :conversations, through: :queues
  has_many :sla_policies, dependent: :nullify

  validates :name,
            presence: { message: I18n.t('errors.validations.presence') },
            uniqueness: { scope: :account_id }

  enum department_type: { support: 0, sales: 1, billing: 2, technical: 3, custom: 4 }

  scope :active, -> { where(active: true) }

  before_validation do
    self.name = name.downcase if attribute_present?('name')
  end

  def total_conversations_count
    conversations.count
  end

  def active_conversations_count
    conversations.where(status: :open).count
  end

  def average_response_time
    conversations.joins(:messages)
                 .where(messages: { message_type: :outgoing })
                 .average('EXTRACT(EPOCH FROM (messages.created_at - conversations.created_at))')&.to_f || 0
  end

  def sla_breach_rate
    return 0 if conversations.empty?

    breached_count = conversations.joins(:applied_slas)
                                  .where(applied_slas: { sla_status: %i[missed active_with_misses] })
                                  .distinct
                                  .count
    
    (breached_count.to_f / conversations.count * 100).round(2)
  end

  def push_event_data
    {
      id: id,
      name: name,
      description: description,
      department_type: department_type,
      active: active
    }
  end
end