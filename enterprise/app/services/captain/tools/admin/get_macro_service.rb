class Captain::Tools::Admin::GetMacroService < Captain::Tools::Admin::BaseTool
  def self.name
    'get_macro'
  end

  description 'Get detailed settings for a specific macro'
  param :macro_id, type: :integer, desc: 'ID of the macro to retrieve', required: true

  def execute(macro_id:)
    macro = account.macros.find_by(id: macro_id)
    return 'Macro not found' if macro.blank?

    format_macro(macro)
  end
end
