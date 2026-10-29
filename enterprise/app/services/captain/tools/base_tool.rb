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

  # RubyLLM checks arguments against execute's signature. A tool whose execute takes options would drop an argument it
  # does not take, such as a filter passed at the top level, and answer as if it had been applied, so its arguments are
  # checked against the declared schema instead. Other tools skip this, because RubyLLM marks every parameter required.
  def call(tool_call: nil, **arguments)
    return super unless method(:execute).parameters.any? { |kind, _| kind == :keyrest }

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
