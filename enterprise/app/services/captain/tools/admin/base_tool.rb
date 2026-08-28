class Captain::Tools::Admin::BaseTool < Captain::Tools::BaseTool
  CONFIRMATION_REQUIRED_MESSAGE = 'This action requires explicit user confirmation. ' \
                                  'Review the pending change in the copilot panel and click Confirm to apply it.'

  def initialize(assistant, user: nil, copilot_thread: nil)
    @copilot_thread = copilot_thread
    super(assistant, user: user)
  end

  def active?
    administrator?
  end

  private

  def administrator?
    return false if @user.blank?

    account_user = AccountUser.find_by(account_id: @assistant.account_id, user_id: @user.id)
    account_user&.administrator?
  end

  def account
    @assistant.account
  end

  def require_confirmation!(confirmed, **action_params)
    return nil if ActiveModel::Type::Boolean.new.cast(confirmed)

    if @copilot_thread.present?
      pending = create_pending_action!(action_params)
      return pending_action_response(pending)
    end

    CONFIRMATION_REQUIRED_MESSAGE
  end

  def create_pending_action!(action_params)
    sanitized_params = action_params.each_with_object({}) do |(key, value), result|
      next if value.nil?

      result[key.to_s] = value
    end

    CopilotPendingAdminAction.create!(
      account: account,
      user: @user,
      copilot_thread: @copilot_thread,
      tool_name: self.class.name,
      action_params: sanitized_params
    )
  end

  def pending_action_response(pending)
    "#{CONFIRMATION_REQUIRED_MESSAGE} Pending change: #{pending.summary}"
  end

  def format_label(label)
    <<~TEXT.strip
      Label ID: #{label.id}
      Title: #{label.title}
      Description: #{label.description}
      Color: #{label.color}
      Show on sidebar: #{label.show_on_sidebar}
    TEXT
  end

  def format_canned_response(canned_response)
    <<~TEXT.strip
      Canned Response ID: #{canned_response.id}
      Short code: #{canned_response.short_code}
      Content: #{canned_response.content}
    TEXT
  end

  def format_macro(macro)
    <<~TEXT.strip
      Macro ID: #{macro.id}
      Name: #{macro.name}
      Visibility: #{macro.visibility}
      Actions: #{macro.actions.to_json}
    TEXT
  end

  def format_inbox(inbox)
    <<~TEXT.strip
      Inbox ID: #{inbox.id}
      Name: #{inbox.name}
      Channel type: #{inbox.channel_type}
      Email: #{inbox.email_address}
      Timezone: #{inbox.timezone}
      Greeting enabled: #{inbox.greeting_enabled}
      Greeting message: #{inbox.greeting_message}
      Out of office message: #{inbox.out_of_office_message}
      Working hours enabled: #{inbox.working_hours_enabled}
      Working hours schedule: #{inbox.weekly_schedule.to_json}
      CSAT survey enabled: #{inbox.csat_survey_enabled}
      CSAT config: #{inbox.csat_config.to_json}
      Enable auto assignment: #{inbox.enable_auto_assignment}
      Enable email collect: #{inbox.enable_email_collect}
      Allow messages after resolved: #{inbox.allow_messages_after_resolved}
      Lock to single conversation: #{inbox.lock_to_single_conversation}
      Business name: #{inbox.business_name}
    TEXT
  end

  def format_automation_rule(rule)
    <<~TEXT.strip
      Automation Rule ID: #{rule.id}
      Name: #{rule.name}
      Description: #{rule.description}
      Event: #{rule.event_name}
      Active: #{rule.active}
      Execution delay (minutes): #{rule.execution_delay}
      Conditions: #{rule.conditions.to_json}
      Actions: #{rule.actions.to_json}
    TEXT
  end

  def parse_json_array(json_string, param_name)
    return nil if json_string.blank?

    parsed = JSON.parse(json_string)
    return parsed if parsed.is_a?(Array)

    "Invalid #{param_name}: expected a JSON array"
  rescue JSON::ParserError
    "Invalid #{param_name}: could not parse JSON"
  end

  def parse_json_object(json_string, param_name)
    return nil if json_string.blank?

    parsed = JSON.parse(json_string)
    return parsed if parsed.is_a?(Hash)

    "Invalid #{param_name}: expected a JSON object"
  rescue JSON::ParserError
    "Invalid #{param_name}: could not parse JSON"
  end

  def json_parse_error?(value)
    value.is_a?(String) && value.start_with?('Invalid ')
  end

  def find_inbox(inbox_id)
    account.inboxes.find_by(id: inbox_id)
  end

  def delayed_automations_enabled?
    account.feature_enabled?('delayed_automations')
  end
end
