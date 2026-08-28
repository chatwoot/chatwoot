class Captain::Tools::Admin::UpdateMacroService < Captain::Tools::Admin::BaseTool
  def self.name
    'update_macro'
  end

  description 'Update a macro. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :macro_id, type: :integer, desc: 'ID of the macro to update', required: true
  param :name, type: :string, desc: 'Macro name'
  param :visibility, type: :string, desc: 'Macro visibility: global or personal'
  param :actions_json, type: :string, desc: 'Actions as a JSON array'

  def execute(confirmed:, macro_id:, name: nil, visibility: nil, actions_json: nil)
    confirmation_error = require_confirmation!(confirmed, macro_id: macro_id, name: name, visibility: visibility, actions_json: actions_json)
    return confirmation_error if confirmation_error.present?

    macro = account.macros.find_by(id: macro_id)
    return 'Macro not found' if macro.blank?

    actions = parse_json_array(actions_json, 'actions_json')
    return actions if json_parse_error?(actions)

    updates = {}
    updates[:name] = name unless name.nil?
    updates[:visibility] = visibility unless visibility.nil?
    macro.actions = actions if actions.present?
    return 'No changes were provided' if updates.blank? && actions.blank?

    macro.assign_attributes(updates)
    macro.updated_by_id = @user.id
    macro.save!

    "Macro updated successfully.\n#{format_macro(macro)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update macro: #{e.record.errors.full_messages.join(', ')}"
  end
end
