module AssigneeActivityMessageHandler
  extend ActiveSupport::Concern

  private

  def create_assignee_change_activity(user_name)
    user_name = activity_message_owner(user_name)

    return unless user_name

    key = assignee_id ? 'assigned' : 'removed'
    key = 'self_assigned' if self_assign? assignee_id
    params = activity_message_params("assignee.#{key}", assignee_name: assignee&.name || '', user_name: user_name, **activity_actor_params)
    ::Conversations::ActivityMessageJob.perform_later(self, params)
  end

  def activity_message_owner(user_name)
    if !user_name && Current.executed_by.present?
      user_name = case Current.executed_by
                  when AssignmentPolicy
                    I18n.t('auto_assignment.policy_actor', policy_name: Current.executed_by.name)
                  when Inbox
                    I18n.t('auto_assignment.default_policy_name')
                  else
                    I18n.t('automation.system_name')
                  end
    end
    user_name
  end

  # Lets clients translate system actors (automation, auto-assignment) in the viewer's locale.
  def activity_actor_params
    case Current.executed_by
    when AssignmentPolicy then { actor_type: 'assignment_policy', policy_name: Current.executed_by.name }
    when Inbox then { actor_type: 'default_policy' }
    when nil then {}
    else { actor_type: 'automation' }
    end
  end
end
