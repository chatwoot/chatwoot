class CrmFlow < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true
  has_many :crm_flow_executions, dependent: :destroy

  TRIGGER_TYPES = %w[
    quote_request
    advisor_transfer
    appointment_scheduling
    lead_creation
    customer_creation
    contact_type_changed
    ticket_created
  ].freeze
  SCOPE_TYPES = %w[global inbox].freeze

  validates :name, presence: true
  validates :trigger_type, inclusion: { in: TRIGGER_TYPES }
  validates :scope_type, inclusion: { in: SCOPE_TYPES }
  validates :inbox, presence: true, if: -> { scope_type == 'inbox' }
  validate :actions_not_empty

  scope :active, -> { where(active: true) }
  scope :by_trigger, ->(type) { where(trigger_type: type) }

  def self.resolve_for(account_id:, trigger_type:, inbox_id: nil)
    base = where(account_id: account_id).active.by_trigger(trigger_type)

    if inbox_id
      flow = base.where(scope_type: 'inbox', inbox_id: inbox_id).first
      return flow if flow
    end

    base.where(scope_type: 'global').first
  end

  def required_custom_fields
    (required_fields || []).select { |f| f['required'] }
  end

  private

  def actions_not_empty
    errors.add(:actions, 'must have at least one action') if actions.blank?
  end
end
