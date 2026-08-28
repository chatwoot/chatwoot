class Captain::Tools::Admin::UpdateInboxWorkingHoursService < Captain::Tools::Admin::BaseTool
  def self.name
    'update_inbox_working_hours'
  end

  description 'Update inbox business hours schedule. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :inbox_id, type: :integer, desc: 'ID of the inbox to update', required: true
  param :working_hours_json, type: :string, desc: 'Working hours as a JSON array of day schedules', required: true

  def execute(confirmed:, inbox_id:, working_hours_json:)
    confirmation_error = require_confirmation!(confirmed, inbox_id: inbox_id, working_hours_json: working_hours_json)
    return confirmation_error if confirmation_error.present?

    inbox = find_inbox(inbox_id)
    return 'Inbox not found' if inbox.blank?

    working_hours = parse_json_array(working_hours_json, 'working_hours_json')
    return working_hours if json_parse_error?(working_hours)
    return 'No working hours were provided' if working_hours.blank?

    inbox.update_working_hours(working_hours)
    "Inbox working hours updated successfully.\n#{format_inbox(inbox.reload)}"
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    "Failed to update inbox working hours: #{e.message}"
  end
end
