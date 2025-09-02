class Queue < ApplicationRecord
  include AccountCacheRevalidator

  belongs_to :account
  belongs_to :department
  belongs_to :sla_policy, optional: true
  has_many :conversations, dependent: :nullify
  has_and_belongs_to_many :agents, class_name: 'User', join_table: 'queue_agents'

  validates :name,
            presence: { message: I18n.t('errors.validations.presence') },
            uniqueness: { scope: :account_id }
  validates :priority, presence: true, inclusion: { in: 1..10 }

  scope :active, -> { where(active: true) }
  scope :by_priority, -> { order(:priority) }
  scope :available, -> { active.where('max_capacity IS NULL OR max_capacity > ?', 0) }

  before_validation do
    self.name = name.downcase if attribute_present?('name')
  end

  def current_load
    conversations.where(status: :open).count
  end

  def capacity_percentage
    return 0 if max_capacity.nil? || max_capacity.zero?
    
    (current_load.to_f / max_capacity * 100).round(2)
  end

  def is_available?
    return false unless active?
    return true if max_capacity.nil?
    
    current_load < max_capacity
  end

  def within_working_hours?
    return true if working_hours.blank?
    
    current_time = Time.current
    current_hour = current_time.hour
    current_day = current_time.strftime('%A').downcase
    
    day_hours = working_hours[current_day]
    return false if day_hours.blank?
    
    start_hour = day_hours['start']&.to_i || 0
    end_hour = day_hours['end']&.to_i || 24
    
    current_hour >= start_hour && current_hour < end_hour
  end

  def next_available_agent
    available_agents = agents.joins(:account_users)
                            .where(account_users: { account_id: account_id })
                            .where('users.availability != ?', User.availabilities[:busy])

    return nil if available_agents.empty?

    # Round-robin or least loaded agent selection
    available_agents.joins("LEFT JOIN conversations ON conversations.assignee_id = users.id AND conversations.status = 0")
                   .group('users.id')
                   .order('COUNT(conversations.id) ASC')
                   .first
  end

  def assign_conversation(conversation)
    return false unless is_available?
    
    agent = next_available_agent
    return false unless agent

    conversation.update!(
      queue_id: id,
      assignee: agent,
      status: :open
    )
    
    true
  end

  def average_wait_time
    recent_conversations = conversations.where(created_at: 30.days.ago..Time.current)
    return 0 if recent_conversations.empty?

    wait_times = recent_conversations.joins(:messages)
                                   .where(messages: { message_type: :outgoing })
                                   .pluck('EXTRACT(EPOCH FROM (messages.created_at - conversations.created_at))')
    
    return 0 if wait_times.empty?
    
    (wait_times.sum / wait_times.count).to_f
  end

  def sla_compliance_rate
    return 100.0 if conversations.empty?

    total_with_sla = conversations.joins(:applied_slas).distinct.count
    return 100.0 if total_with_sla.zero?

    compliant_count = conversations.joins(:applied_slas)
                                  .where(applied_slas: { sla_status: %i[active hit] })
                                  .distinct
                                  .count

    (compliant_count.to_f / total_with_sla * 100).round(2)
  end

  def push_event_data
    {
      id: id,
      name: name,
      description: description,
      department_id: department_id,
      sla_policy_id: sla_policy_id,
      priority: priority,
      active: active,
      current_load: current_load,
      capacity_percentage: capacity_percentage
    }
  end
end