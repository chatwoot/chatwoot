class ConversationMonitors::ProcessAutomationDeliveryJob < ApplicationJob
  queue_as :medium

  def perform(delivery_id)
    delivery = ConversationMonitors::AutomationDelivery.find_by(id: delivery_id)
    return unless delivery
    return unless claim(delivery)

    conditions_match = delivery.automation_rule.conditions.blank? ||
                       AutomationRules::ConditionsFilterService.new(delivery.automation_rule, delivery.conversation).perform.present?
    return unless begin_execution(delivery, conditions_match)

    AutomationRules::ActionService.new(delivery.automation_rule, delivery.account, delivery.conversation).perform
    delivery.update!(status: 'executed')
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: delivery&.account).capture_exception
  end

  private

  def claim(delivery)
    delivery.monitor.with_lock do
      delivery.with_lock do
        stale_processing = delivery.status == 'processing' &&
                           delivery.updated_at < ConversationMonitors::AutomationDelivery::STALE_PROCESSING_TIMEOUT.ago
        next false unless delivery.status == 'pending' || stale_processing

        unless eligible?(delivery)
          delivery.update!(status: 'skipped', skip_reason: 'monitor_or_rule_unavailable')
          next false
        end

        delivery.update!(status: 'processing', claimed_at: Time.current)
        true
      end
    end
  end

  def begin_execution(delivery, conditions_match)
    delivery.monitor.with_lock do
      delivery.with_lock do
        next false unless delivery.status == 'processing'

        unless eligible?(delivery) && conditions_match
          delivery.update!(status: 'skipped', skip_reason: conditions_match ? 'monitor_or_rule_unavailable' : 'conditions_changed')
          next false
        end

        delivery.update!(status: 'executing')
        true
      end
    end
  end

  def eligible?(delivery)
    rule = delivery.automation_rule.reload
    monitor = delivery.monitor.reload
    monitor.collecting? && monitor.account.feature_enabled?('automations') &&
      rule.active? && rule.event_name == 'monitor_matched' && rule.monitor_id == monitor.id &&
      delivery.account_id == monitor.account_id && delivery.conversation.account_id == monitor.account_id
  end
end
