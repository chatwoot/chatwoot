class Captain::Tools::BaseTool < RubyLLM::Tool
  prepend Captain::Tools::Instrumentation

  attr_accessor :assistant

  def initialize(assistant, user: nil)
    @assistant = assistant
    @user = user
    super()
  end

  def active?
    true
  end

  # Checks the arguments against the declared schema before RubyLLM checks them against execute's signature. A tool
  # whose execute takes options would otherwise drop an argument it does not take, such as a filter passed at the top
  # level, and answer as if it had been applied.
  def call(tool_call: nil, **arguments)
    errors = Captain::Copilot::SchemaErrors.messages(parameters_schema.to_h, arguments)
    return super if errors.empty?

    allowed = parameters_schema.to_h.stringify_keys.fetch('properties', {}).keys
    { error: "Invalid tool arguments: #{errors.join('; ')}. Arguments: #{allowed.join(', ')}" }
  end

  private

  def user_has_permission(permission)
    return false if @user.blank?

    account_user = AccountUser.find_by(account_id: @assistant.account_id, user_id: @user.id)
    return false if account_user.blank?

    return account_user.custom_role.permissions.include?(permission) if account_user.custom_role.present?

    account_user.administrator? || account_user.agent?
  end
end
