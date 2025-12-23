# rubocop:disable Metrics/ModuleLength
module ActivityMessageHandler
  extend ActiveSupport::Concern

  include PriorityActivityMessageHandler
  include LabelActivityMessageHandler
  include SlaActivityMessageHandler
  include TeamActivityMessageHandler
  include CallingStatusActivityMessageHandler

  private

  def create_activity
    user_name = determine_user_name

    handle_status_change(user_name)
    handle_priority_change(user_name)
    handle_label_change(user_name)
    handle_sla_policy_change(user_name)
    handle_calling_status_change(user_name)
  end

  def determine_user_name
    Current.user&.name
  end

  def handle_status_change(user_name)
    return unless saved_change_to_status?

    status_change_activity(user_name)
  end

  def handle_calling_status_change(user_name)
    return unless saved_change_to_custom_attributes?

    old_status = previous_changes['custom_attributes'][0]['calling_status']
    new_status = previous_changes['custom_attributes'][1]['calling_status']

    return unless new_status.present? && old_status != new_status

    calling_status_change_activity(user_name)
  end

  def handle_priority_change(user_name)
    return unless saved_change_to_priority?

    priority_change_activity(user_name)
  end

  def handle_label_change(user_name)
    return unless saved_change_to_label_list?

    create_label_change(activity_message_owner(user_name))
  end

  def handle_sla_policy_change(user_name)
    return unless saved_change_to_sla_policy_id?

    sla_change_type = determine_sla_change_type
    create_sla_change_activity(sla_change_type, activity_message_owner(user_name))
  end

  def status_change_activity(user_name)
    content = if Current.executed_by.present?
                automation_status_change_activity_content
              else
                user_status_change_activity_content(user_name)
              end

    return unless content

    # Capture the current user/executor for background job
    current_user_id = Current.user&.id || (Current.executed_by.is_a?(User) ? Current.executed_by.id : nil)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content), current_user_id)
  end

  def calling_status_change_activity(user_name)
    content = if Current.executed_by.present?
                automation_calling_status_change_activity_content
              else
                user_calling_status_change_activity_content(user_name)
              end

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def user_status_change_activity_content(user_name)
    if user_name
      I18n.t("conversations.activity.status.#{status}", user_name: user_name)
    elsif Current.contact.present? && resolved?
      I18n.t('conversations.activity.status.contact_resolved', contact_name: Current.contact.name.capitalize)
    elsif resolved?
      if web_widget?
        'Conversation was marked resolved'
      else
        I18n.t('conversations.activity.status.auto_resolved', duration: auto_resolve_duration)
      end
    end
  end

  def user_calling_status_change_activity_content(user_name)
    return unless user_name

    calling_status_change_activity_content(user_name, previous_changes['custom_attributes'][1]['calling_status'])
  end

  def automation_status_change_activity_content
    if Current.executed_by.instance_of?(AutomationRule)
      I18n.t("conversations.activity.status.#{status}", user_name: 'Automation System')
    elsif Current.executed_by.instance_of?(Contact)
      Current.executed_by = nil
      I18n.t('conversations.activity.status.system_auto_open')
    end
  end

  def automation_calling_status_change_activity_content
    return unless Current.executed_by.instance_of?(AutomationRule)

    calling_status_change_activity_content(user_name, previous_changes['custom_attributes'][1]['calling_status'])
  end

  def activity_message_params(content)
    { account_id: account_id, inbox_id: inbox_id, message_type: :activity, content: content }
  end

  def create_muted_message
    create_mute_change_activity('muted')
  end

  def create_unmuted_message
    create_mute_change_activity('unmuted')
  end

  def create_mute_change_activity(change_type)
    return unless Current.user

    content = I18n.t("conversations.activity.#{change_type}", user_name: Current.user.name)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def generate_assignee_change_activity_content(user_name)
    params = { assignee_name: assignee&.name, user_name: user_name }.compact
    key = assignee_id ? 'assigned' : 'removed'
    key = 'self_assigned' if self_assign? assignee_id
    I18n.t("conversations.activity.assignee.#{key}", **params)
  end

  def create_assignee_change_activity(user_name)
    user_name = activity_message_owner(user_name)

    return unless user_name

    content = generate_assignee_change_activity_content(user_name)
    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
  end

  def activity_message_owner(user_name)
    user_name = 'Automation System' if !user_name && Current.executed_by.present?
    user_name
  end
end
# rubocop:enable Metrics/ModuleLength
