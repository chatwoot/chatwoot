class Captain::Tools::Admin::DeleteInboxService < Captain::Tools::Admin::BaseTool
  def self.name
    'delete_inbox'
  end

  description 'Delete an inbox and its channel. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :inbox_id, type: :integer, desc: 'ID of the inbox to delete', required: true

  def execute(confirmed:, inbox_id:)
    confirmation_error = require_confirmation!(confirmed, inbox_id: inbox_id)
    return confirmation_error if confirmation_error.present?

    inbox = find_inbox(inbox_id)
    return 'Inbox not found' if inbox.blank?

    inbox_name = inbox.name
    ::DeleteObjectJob.perform_later(inbox, @user, nil)

    "Inbox '#{inbox_name}' deletion has been scheduled."
  end
end
