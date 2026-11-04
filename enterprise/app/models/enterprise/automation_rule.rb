module Enterprise::AutomationRule
  def self.prepended(base)
    base.belongs_to :monitor, class_name: 'ConversationMonitors::Monitor', optional: true, inverse_of: :automation_rules
    base.has_many :monitor_automation_deliveries, class_name: 'ConversationMonitors::AutomationDelivery', dependent: :delete_all
    base.before_validation :prepare_monitor_event
    base.validate :validate_monitor_event
    base.after_update :discard_stale_monitor_deliveries,
                      if: -> { execution_config_changed? || saved_change_to_monitor_id? }
  end

  def conditions_attributes
    super + %w[sla_policy_id]
  end

  def actions_attributes
    super + %w[add_sla]
  end

  def monitor_availability
    return unless event_name == 'monitor_matched'
    return 'deleted' unless monitor && monitor.deleted_at.nil?
    return 'paused' if monitor.paused_at
    return 'unavailable' unless monitor.collecting? && monitor.account.feature_enabled?('automations')

    'available'
  end

  def destroy
    return super unless monitor_id

    ConversationMonitors::Monitor.transaction do
      # Match ResultWriter's monitor lock before deleting the rule and its deliveries.
      ConversationMonitors::Monitor.lock.find_by(id: monitor_id)
      super
    end
  end

  private

  def prepare_monitor_event
    unless event_name == 'monitor_matched'
      self.monitor_id = nil
      self.monitor_event_activated_at = nil
      return
    end

    return unless active? && monitor_activation_changed?

    self.monitor_event_activated_at = Time.current
  end

  def monitor_activation_changed?
    new_record? || will_save_change_to_active? || will_save_change_to_monitor_id? || will_save_change_to_event_name? ||
      will_save_change_to_conditions? || will_save_change_to_actions?
  end

  def validate_monitor_event
    return unless event_name == 'monitor_matched'

    validate_monitor_identity
    errors.add(:execution_delay, 'is not supported for monitor events') if execution_delay.present?
    return unless active? || new_record? || will_save_change_to_monitor_id? || will_save_change_to_event_name?

    validate_monitor_activation
  end

  def validate_monitor_activation
    errors.add(:monitor, 'must be active') unless monitor&.collecting?
    errors.add(:base, 'Monitor automations are not enabled for this account') unless account&.feature_enabled?('automations')
  end

  def validate_monitor_identity
    errors.add(:monitor, 'must belong to this account') if monitor && monitor.account_id != account_id
    errors.add(:monitor, 'is required') if monitor_required?
  end

  def monitor_required?
    return false if monitor

    new_record? || active? || will_save_change_to_monitor_id? || will_save_change_to_event_name?
  end

  def discard_stale_monitor_deliveries
    # Rows queued under an old definition must be invalidated atomically with the rule update.
    # rubocop:disable Rails/SkipsModelValidations
    monitor_automation_deliveries.where(status: %w[pending processing])
                                 .update_all(status: 'skipped', skip_reason: 'rule_changed', updated_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations
  end
end
