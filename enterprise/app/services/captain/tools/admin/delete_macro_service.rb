class Captain::Tools::Admin::DeleteMacroService < Captain::Tools::Admin::BaseTool
  def self.name
    'delete_macro'
  end

  description 'Delete a macro. Requires user confirmation.'
  param :confirmed, type: :boolean, desc: 'Must be true after the user explicitly confirms the change', required: true
  param :macro_id, type: :integer, desc: 'ID of the macro to delete', required: true

  def execute(confirmed:, macro_id:)
    confirmation_error = require_confirmation!(confirmed, macro_id: macro_id)
    return confirmation_error if confirmation_error.present?

    macro = account.macros.find_by(id: macro_id)
    return 'Macro not found' if macro.blank?

    macro_name = macro.name
    macro.destroy!

    "Macro '#{macro_name}' deleted successfully."
  end
end
