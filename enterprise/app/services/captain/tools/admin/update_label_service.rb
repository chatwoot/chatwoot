class Captain::Tools::Admin::UpdateLabelService < Captain::Tools::Admin::BaseTool
  def self.name
    'update_label'
  end

  description 'Update an existing label. Requires user confirmation before applying changes.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :label_id, type: :integer, desc: 'ID of the label to update', required: true
  param :title, type: :string, desc: 'Label title'
  param :description, type: :string, desc: 'Label description'
  param :color, type: :string, desc: 'Label color hex code (e.g. #1f93ff)'
  param :show_on_sidebar, type: :boolean, desc: 'Whether to show the label on the sidebar'

  def execute(confirmed:, label_id:, title: nil, description: nil, color: nil, show_on_sidebar: nil)
    confirmation_error = require_confirmation!(confirmed, label_id: label_id, title: title, description: description, color: color,
                                                          show_on_sidebar: show_on_sidebar)
    return confirmation_error if confirmation_error.present?

    label = account.labels.find_by(id: label_id)
    return 'Label not found' if label.blank?

    updates = label_updates(title: title, description: description, color: color, show_on_sidebar: show_on_sidebar)
    return 'No changes were provided' if updates.blank?

    label.update!(updates)

    "Label updated successfully.\n#{format_label(label)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update label: #{e.record.errors.full_messages.join(', ')}"
  end

  private

  def label_updates(title:, description:, color:, show_on_sidebar:)
    {}.tap do |updates|
      updates[:title] = title unless title.nil?
      updates[:description] = description unless description.nil?
      updates[:color] = color unless color.nil?
      updates[:show_on_sidebar] = show_on_sidebar unless show_on_sidebar.nil?
    end
  end
end
