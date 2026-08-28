class Captain::Tools::Admin::ListMacrosService < Captain::Tools::Admin::BaseTool
  def self.name
    'list_macros'
  end

  description 'List macros configured for the account'
  param :search, type: :string, desc: 'Optional filter by macro name (partial match)'

  def execute(search: nil)
    macros = account.macros
    macros = macros.where('name ILIKE ?', "%#{search}%") if search.present?

    return 'No macros found' if macros.none?

    macros.limit(100).map { |macro| format_macro(macro) }.join("\n---\n")
  end
end
