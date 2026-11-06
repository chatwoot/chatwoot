# A custom tool in a conversation where a customer is the user. A tool that requires email verification runs only
# for a customer who verified an email, and a verified email parameter always carries that email.
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  def perform(tool_context, **params)
    return super unless @custom_tool.requires_email_verification?

    verified_email = stored_verified_email(tool_context.state)
    return failure_result(Captain::ParamSources::UNVERIFIED, tool_context.state) unless verified_email

    # Set last, so a value from the model can never replace the verified email
    email_param = @custom_tool.verified_email_param
    super(tool_context, **(email_param ? params.merge(email_param.to_sym => verified_email) : params))
  end
end
