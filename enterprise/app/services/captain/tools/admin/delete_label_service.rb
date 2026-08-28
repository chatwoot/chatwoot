class Captain::Tools::Admin::DeleteLabelService < Captain::Tools::Admin::BaseTool
  def self.name
    'delete_label'
  end

  description 'Delete a label. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :label_id, type: :integer, desc: 'ID of the label to delete', required: true

  def execute(confirmed:, label_id:)
    confirmation_error = require_confirmation!(confirmed, label_id: label_id)
    return confirmation_error if confirmation_error.present?

    label = account.labels.find_by(id: label_id)
    return 'Label not found' if label.blank?

    label_title = label.title
    label.destroy!
    Labels::RemoveAssociationsJob.perform_later(
      label_title: label_title,
      account_id: account.id,
      label_deleted_at: Time.current
    )

    "Label '#{label_title}' deleted successfully."
  end
end
