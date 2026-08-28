class Captain::Tools::Admin::DeleteCannedResponseService < Captain::Tools::Admin::BaseTool
  def self.name
    'delete_canned_response'
  end

  description 'Delete a canned response. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :canned_response_id, type: :integer, desc: 'ID of the canned response to delete', required: true

  def execute(confirmed:, canned_response_id:)
    confirmation_error = require_confirmation!(confirmed, canned_response_id: canned_response_id)
    return confirmation_error if confirmation_error.present?

    canned_response = account.canned_responses.find_by(id: canned_response_id)
    return 'Canned response not found' if canned_response.blank?

    short_code = canned_response.short_code
    canned_response.destroy!

    "Canned response '#{short_code}' deleted successfully."
  end
end
