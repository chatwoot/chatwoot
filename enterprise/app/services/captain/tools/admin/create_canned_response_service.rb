class Captain::Tools::Admin::CreateCannedResponseService < Captain::Tools::Admin::BaseTool
  def self.name
    'create_canned_response'
  end

  description 'Create a new canned response. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :short_code, type: :string, desc: 'Short code used to insert the canned response', required: true
  param :content, type: :string, desc: 'Canned response content', required: true

  def execute(confirmed:, short_code:, content:)
    confirmation_error = require_confirmation!(confirmed, short_code: short_code, content: content)
    return confirmation_error if confirmation_error.present?

    canned_response = account.canned_responses.create!(short_code: short_code, content: content)

    "Canned response created successfully.\n#{format_canned_response(canned_response)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create canned response: #{e.record.errors.full_messages.join(', ')}"
  end
end
