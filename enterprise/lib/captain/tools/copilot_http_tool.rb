# A custom tool where an admin or an agent is the user: the playground and reply suggestions.
# The model fills verified parameters with the value it was given, and the result says when that value is not one the customer verified.
class Captain::Tools::CopilotHttpTool < Captain::Tools::HttpTool
  UNVERIFIED_VALUE_NOTE = 'The email passed to this tool was not verified by the customer.'.freeze

  def self.model_fills_verified_values?
    true
  end

  def perform(tool_context, **params)
    email_param = @custom_tool.verified_email_param
    return super unless email_param

    result = super
    verified_email = stored_verified_email(tool_context.state)
    verified_email && params[email_param.to_sym].to_s.strip.casecmp?(verified_email) ? result : "#{result}\n\n#{UNVERIFIED_VALUE_NOTE}"
  end
end
