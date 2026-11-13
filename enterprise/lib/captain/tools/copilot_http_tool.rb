# A custom tool where an admin or an agent is the user: the playground and reply suggestions.
# The model fills verified parameters with the value it was given, and the result says when that value is not one the customer verified.
class Captain::Tools::CopilotHttpTool < Captain::Tools::HttpTool
  def self.model_fills_verified_values?
    true
  end

  private

  def arguments_for(_tool_context, params)
    params
  end

  def annotate(result, tool_context, params)
    email_param = @custom_tool.verified_email_param
    return result unless email_param

    verified_email = Captain::ParamSources.stored_verified_email(find_conversation(tool_context.state))
    return result if verified_email && params[email_param.to_sym].to_s.strip.casecmp?(verified_email)

    "#{result}\n\n#{Captain::ParamSources::UNVERIFIED_VALUE_NOTE}"
  end
end
