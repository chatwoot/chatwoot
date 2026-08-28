class Captain::Tools::Admin::UpdateCannedResponseService < Captain::Tools::Admin::BaseTool
  def self.name
    'update_canned_response'
  end

  description 'Update an existing canned response. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :canned_response_id, type: :integer, desc: 'ID of the canned response to update', required: true
  param :short_code, type: :string, desc: 'Short code used to insert the canned response'
  param :content, type: :string, desc: 'Canned response content'

  def execute(confirmed:, canned_response_id:, short_code: nil, content: nil)
    confirmation_error = require_confirmation!(confirmed, canned_response_id: canned_response_id, short_code: short_code, content: content)
    return confirmation_error if confirmation_error.present?

    canned_response = account.canned_responses.find_by(id: canned_response_id)
    return 'Canned response not found' if canned_response.blank?

    updates = {}
    updates[:short_code] = short_code unless short_code.nil?
    updates[:content] = content unless content.nil?

    return 'No changes were provided' if updates.blank?

    canned_response.update!(updates)

    "Canned response updated successfully.\n#{format_canned_response(canned_response)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update canned response: #{e.record.errors.full_messages.join(', ')}"
  end
end
