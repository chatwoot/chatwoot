module ActivityMessageHandler
  extend ActiveSupport::Concern

  include PriorityActivityMessageHandler
  include LabelActivityMessageHandler
  include SlaActivityMessageHandler
  include TeamActivityMessageHandler

  private

  def create_activity
    debug_file = "tmp/conversation-#{id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n========== CREATE_ACTIVITY START =========="
      f.puts "Time: #{Time.current}"
      f.puts "Conversation ID: #{id}"
      f.puts "Current.executed_by: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "Current.user: #{Current.user&.class&.name} - #{Current.user&.id}"
      f.puts "saved_change_to_status?: #{saved_change_to_status?}"
      f.puts "saved_change_to_priority?: #{saved_change_to_priority?}"
      f.puts "saved_change_to_label_list?: #{saved_change_to_label_list?}"
      f.puts "saved_change_to_sla_policy_id?: #{saved_change_to_sla_policy_id?}"
      f.puts "Status: #{status}"
      f.puts "Previous changes: #{previous_changes.inspect}"
    end

    user_name = determine_user_name

    File.open(debug_file, 'a') do |f|
      f.puts "\nDetermined user_name: #{user_name.inspect}"
    end

    handle_status_change(user_name)
    handle_priority_change(user_name)
    handle_label_change(user_name)
    handle_sla_policy_change(user_name)

    File.open(debug_file, 'a') do |f|
      f.puts "========== CREATE_ACTIVITY END ==========\n"
    end
  end

  def determine_user_name
    Current.user&.name
  end

  def handle_status_change(user_name)
    debug_file = "tmp/conversation-#{id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n----- handle_status_change START -----"
      f.puts "saved_change_to_status?: #{saved_change_to_status?}"
      f.puts "user_name: #{user_name.inspect}"
      f.puts "Current.executed_by: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
    end

    return unless saved_change_to_status?

    status_change_activity(user_name)

    File.open(debug_file, 'a') do |f|
      f.puts "----- handle_status_change END -----\n"
    end
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
    debug_file = "tmp/conversation-#{id}.txt"

    File.open(debug_file, 'a') do |f|
      f.puts "\n----- status_change_activity START -----"
      f.puts "Time: #{Time.current}"
      f.puts "user_name: #{user_name.inspect}"
      f.puts "Current.executed_by: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "Current.executed_by present?: #{Current.executed_by.present?}"
      f.puts "Will call automation_status_change_activity_content?: #{Current.executed_by.present?}"
    end

    content = if Current.executed_by.present?
                File.open(debug_file, 'a') { |f| f.puts 'Calling automation_status_change_activity_content' }
                automation_status_change_activity_content
              else
                File.open(debug_file, 'a') { |f| f.puts 'Calling user_status_change_activity_content' }
                user_status_change_activity_content(user_name)
              end

    File.open(debug_file, 'a') do |f|
      f.puts "Content generated: #{content.inspect}"
      f.puts "Will enqueue ActivityMessageJob?: #{content.present?}"
      f.puts "Enqueueing ActivityMessageJob with params: #{activity_message_params(content).inspect}" if content
      f.puts "----- status_change_activity END -----\n"
    end

    ::Conversations::ActivityMessageJob.perform_later(self, activity_message_params(content)) if content
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

  def user_status_change_activity_content(user_name)
    if user_name
      I18n.t("conversations.activity.status.#{status}", user_name: user_name)
    elsif Current.contact.present? && resolved?
      I18n.t('conversations.activity.status.contact_resolved', contact_name: Current.contact.name.capitalize)
    elsif resolved?
      message_data = auto_resolve_message_key(auto_resolve_after || 0)
      I18n.t("conversations.activity.status.#{message_data[:key]}", count: message_data[:count])
    end
  end

  def automation_status_change_activity_content
    if Current.executed_by.instance_of?(AutomationRule)
      I18n.t("conversations.activity.status.#{status}", user_name: I18n.t('automation.system_name'))
    elsif Current.executed_by.instance_of?(Contact)
      Current.executed_by = nil
      I18n.t('conversations.activity.status.system_auto_open')
    end
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
    params = { assignee_name: assignee&.name || '', user_name: user_name }
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
    user_name = I18n.t('automation.system_name') if !user_name && Current.executed_by.present?
    user_name
  end
end

ActivityMessageHandler.prepend_mod_with('ActivityMessageHandler')
