module ActivityMessageHandler
  extend ActiveSupport::Concern

  include AssigneeActivityMessageHandler
  include PriorityActivityMessageHandler
  include LabelActivityMessageHandler
  include SlaActivityMessageHandler
  include TeamActivityMessageHandler

  private

  def create_activity
    user_name = determine_user_name

    handle_status_change(user_name)
    handle_priority_change(user_name)
    handle_label_change(user_name)
    handle_sla_policy_change(user_name)
  end

  def determine_user_name
    Current.user&.name
  end

  def handle_status_change(user_name)
    return unless saved_change_to_status?

    status_change_activity(user_name)
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
    params = if Current.executed_by.present?
               automation_status_change_activity_params
             else
               user_status_change_activity_params(user_name)
             end

    return if params.blank?

    ::Conversations::ActivityMessageJob.perform_later(self, params)
  end

  def auto_resolve_message_key(minutes)
    if minutes >= 1440 && (minutes % 1440).zero?
      { key: 'auto_resolved_days', count: minutes / 1440 }
    elsif minutes >= 60 && (minutes % 60).zero?
      { key: 'auto_resolved_hours', count: minutes / 60 }
    else
      { key: 'auto_resolved_minutes', count: minutes }
    end
  end

  def user_status_change_activity_params(user_name)
    if user_name
      status_activity_params(status, user_name: user_name)
    elsif Current.contact.present? && resolved?
      status_activity_params('contact_resolved', contact_name: Current.contact.name.capitalize)
    elsif resolved?
      message_data = auto_resolve_message_key(auto_resolve_after || 0)
      status_activity_params(message_data[:key], count: message_data[:count])
    end
  end

  def automation_status_change_activity_params
    if Current.executed_by.instance_of?(AutomationRule)
      status_activity_params(status, user_name: I18n.t('automation.system_name'), actor_type: 'automation')
    elsif Current.executed_by.instance_of?(Contact)
      Current.executed_by = nil
      status_activity_params('system_auto_open')
    end
  end

  def status_activity_params(key, **i18n_params)
    activity_message_params(
      "status.#{key}",
      content_attributes: { activity: { type: 'conversation_status_changed', status: status } },
      **i18n_params
    )
  end

  # Stores the activity key and params next to the rendered content so clients can translate it
  # in the viewer's locale. `content` stays populated for API, webhook and transcript consumers.
  def activity_message_params(key, content_attributes: {}, **i18n_params)
    {
      account_id: account_id, inbox_id: inbox_id, message_type: :activity,
      content: I18n.t("conversations.activity.#{key}", **i18n_params),
      content_attributes: { activity: { key: key, params: i18n_params } }.deep_merge(content_attributes)
    }
  end

  def create_muted_message
    create_mute_change_activity('muted')
  end

  def create_unmuted_message
    create_mute_change_activity('unmuted')
  end

  def create_mute_change_activity(change_type)
    return unless Current.user

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(change_type, user_name: Current.user.name))
  end
end

ActivityMessageHandler.prepend_mod_with('ActivityMessageHandler')
