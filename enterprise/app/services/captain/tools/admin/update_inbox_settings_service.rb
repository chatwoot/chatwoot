class Captain::Tools::Admin::UpdateInboxSettingsService < Captain::Tools::Admin::BaseTool
  INBOX_ATTRIBUTES = %i[
    name greeting_enabled greeting_message enable_email_collect csat_survey_enabled
    enable_auto_assignment working_hours_enabled out_of_office_message timezone
    allow_messages_after_resolved lock_to_single_conversation business_name
  ].freeze

  def self.name
    'update_inbox_settings'
  end

  description 'Update inbox settings such as greeting, CSAT, timezone, and auto-assignment. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :inbox_id, type: :integer, desc: 'ID of the inbox to update', required: true
  param :name, type: :string, desc: 'Inbox name'
  param :greeting_enabled, type: :boolean, desc: 'Whether the greeting message is enabled'
  param :greeting_message, type: :string, desc: 'Greeting message shown to customers'
  param :enable_email_collect, type: :boolean, desc: 'Whether to collect email from visitors'
  param :csat_survey_enabled, type: :boolean, desc: 'Whether CSAT surveys are enabled'
  param :enable_auto_assignment, type: :boolean, desc: 'Whether conversations are auto-assigned'
  param :working_hours_enabled, type: :boolean, desc: 'Whether business hours are enforced'
  param :out_of_office_message, type: :string, desc: 'Message shown outside business hours'
  param :timezone, type: :string, desc: 'Inbox timezone (e.g. UTC, America/New_York)'
  param :allow_messages_after_resolved, type: :boolean, desc: 'Whether customers can message after resolution'
  param :lock_to_single_conversation, type: :boolean, desc: 'Whether contacts are limited to one conversation'
  param :business_name, type: :string, desc: 'Business name shown in the inbox'
  param :csat_config_json, type: :string, desc: 'CSAT configuration as a JSON object'

  def execute(confirmed:, inbox_id:, csat_config_json: nil, **attributes)
    confirmation_error = require_confirmation!(confirmed, inbox_id: inbox_id, csat_config_json: csat_config_json, **attributes)
    return confirmation_error if confirmation_error.present?

    inbox = find_inbox(inbox_id)
    return 'Inbox not found' if inbox.blank?

    updates = inbox_updates(attributes)
    csat_config = parse_json_object(csat_config_json, 'csat_config_json')
    return csat_config if json_parse_error?(csat_config)

    updates[:csat_config] = csat_config if csat_config.present?
    return 'No changes were provided' if updates.blank?

    inbox.update!(updates)
    "Inbox settings updated successfully.\n#{format_inbox(inbox.reload)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update inbox settings: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def inbox_updates(attributes)
    attributes.each_with_object({}) do |(key, value), updates|
      next unless INBOX_ATTRIBUTES.include?(key.to_sym)
      next if value.nil?

      updates[key.to_sym] = value
    end
  end
end
