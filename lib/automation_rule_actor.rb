# frozen_string_literal: true

module AutomationRuleActor
  module_function

  def activity_owner(user_name)
    return user_name if user_name.present?
    return nil unless Current.executed_by.present?

    case Current.executed_by
    when AutomationRule
      I18n.t('automation.activity_actor', name: Current.executed_by.name)
    when AssignmentPolicy
      I18n.t('auto_assignment.policy_actor', policy_name: Current.executed_by.name)
    when Inbox
      I18n.t('auto_assignment.default_policy_name')
    else
      I18n.t('automation.system_name')
    end
  end
end
