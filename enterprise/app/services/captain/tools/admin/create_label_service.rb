class Captain::Tools::Admin::CreateLabelService < Captain::Tools::Admin::BaseTool
  def self.name
    'create_label'
  end

  description 'Create a new label. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :title, type: :string, desc: 'Label title', required: true
  param :description, type: :string, desc: 'Label description'
  param :color, type: :string, desc: 'Label color hex code (e.g. #1f93ff)'
  param :show_on_sidebar, type: :boolean, desc: 'Whether to show the label on the sidebar'

  def execute(confirmed:, title:, description: nil, color: nil, show_on_sidebar: nil)
    confirmation_error = require_confirmation!(confirmed, title: title, description: description, color: color, show_on_sidebar: show_on_sidebar)
    return confirmation_error if confirmation_error.present?

    label = account.labels.create!(
      title: title,
      description: description,
      color: color,
      show_on_sidebar: show_on_sidebar
    )

    "Label created successfully.\n#{format_label(label)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create label: #{e.record.errors.full_messages.join(', ')}"
  end
end
