# A custom tool in a conversation where a customer is the user. A tool that needs a verified customer runs only
# for a customer who verified an email, and a verified email parameter always carries that email.
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  private

  def arguments_for(tool_context, params)
    return params unless @custom_tool.requires_verified_customer?

    verified_email = Captain::ParamSources.verified_email(find_conversation(tool_context.state))
    # Set last, so a value from the model can never replace the verified email
    email_param = @custom_tool.verified_email_param
    email_param ? params.merge(email_param.to_sym => verified_email) : params
  end
end
