class ConversationMonitors::ProcessAutomationDeliveryJob < ApplicationJob
  queue_as :medium

  def perform(delivery_id)
    delivery = ConversationMonitors::AutomationDelivery.find_by(id: delivery_id)
    return unless delivery
    return unless claim(delivery)

    rule = delivery.automation_rule
    conversation = delivery.conversation
    conditions_match = conditions_match?(rule, conversation)
    return unless begin_execution(delivery, conditions_match)

    AutomationRules::ActionService.new(rule, delivery.account, conversation).perform
    delivery.update!(status: 'executed')
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: delivery&.account).capture_exception
  end

  private

  def conditions_match?(rule, conversation)
    return false unless rule && conversation

    rule.conditions.blank? || AutomationRules::ConditionsFilterService.new(rule, conversation).perform.present?
  end

  def claim(delivery)
    monitor = delivery.monitor
    return skip_orphaned(delivery) unless monitor

    monitor.with_lock do
      delivery.with_lock do
        stale_processing = delivery.status == 'processing' &&
                           delivery.updated_at < ConversationMonitors::AutomationDelivery::STALE_PROCESSING_TIMEOUT.ago
        next false unless delivery.status == 'pending' || stale_processing

        unless eligible?(delivery)
          mark_unavailable(delivery)
          next false
        end

        delivery.update!(status: 'processing', claimed_at: Time.current)
        true
      end
    end
  rescue ActiveRecord::RecordNotFound
    skip_orphaned(delivery)
  end

  def begin_execution(delivery, conditions_match)
    monitor = delivery.monitor
    return skip_orphaned(delivery) unless monitor

    monitor.with_lock do
      delivery.with_lock do
        next false unless delivery.status == 'processing'

        unless eligible?(delivery)
          mark_unavailable(delivery)
          next false
        end

        unless conditions_match
          delivery.update!(status: 'skipped', skip_reason: 'conditions_changed')
          next false
        end

        delivery.update!(status: 'executing')
        true
      end
    end
  rescue ActiveRecord::RecordNotFound
    skip_orphaned(delivery)
  end

  def eligible?(delivery)
    rule = delivery.automation_rule
    conversation = delivery.conversation
    return false unless rule && conversation

    rule.reload
    monitor = delivery.monitor.reload
    monitor.collecting? && monitor.account.feature_enabled?('automations') &&
      eligible_rule?(rule, monitor, conversation, delivery.account_id)
  rescue ActiveRecord::RecordNotFound
    false
  end

  def eligible_rule?(rule, monitor, conversation, account_id)
    rule.active? && rule.event_name == 'monitor_matched' && rule.monitor_id == monitor.id &&
      account_id == monitor.account_id && conversation.account_id == monitor.account_id
  end

  def skip_orphaned(delivery)
    delivery.with_lock do
      mark_unavailable(delivery) if delivery.status.in?(%w[pending processing])
    end
    false
  rescue ActiveRecord::RecordNotFound
    false
  end

  def mark_unavailable(delivery)
    # Orphaned deliveries cannot pass association validations.
    delivery.update_columns(status: 'skipped', skip_reason: 'monitor_or_rule_unavailable', updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
  end
end
