class Captain::Tools::Admin::CreateMacroService < Captain::Tools::Admin::BaseTool
  def self.name
    'create_macro'
  end

  description 'Create a macro. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :name, type: :string, desc: 'Macro name', required: true
  param :actions_json, type: :string, desc: 'Actions as a JSON array', required: true
  param :visibility, type: :string, desc: 'Macro visibility: global or personal'

  def execute(confirmed:, name:, actions_json:, visibility: 'global')
    confirmation_error = require_confirmation!(confirmed, name: name, actions_json: actions_json, visibility: visibility)
    return confirmation_error if confirmation_error.present?

    actions = parse_json_array(actions_json, 'actions_json')
    return actions if json_parse_error?(actions)

    macro = account.macros.new(
      name: name,
      visibility: visibility,
      actions: actions,
      created_by_id: @user.id,
      updated_by_id: @user.id
    )
    macro.save!

    "Macro created successfully.\n#{format_macro(macro)}"
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create macro: #{e.record.errors.full_messages.join(', ')}"
  end
end
