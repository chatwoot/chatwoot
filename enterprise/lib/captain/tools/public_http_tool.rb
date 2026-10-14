# A custom tool in a conversation where a customer is the user. A tool that requires email verification runs only
# for a customer who verified an email, and that email is the only email the request can carry.
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  EMAIL_IN_TEXT_PATTERN = /[^\s@<>"',;:()]+@[^\s@<>"',;:()]+/
  EMAIL_REQUIRED = 'This tool needs a verified email, and this customer has not verified an email yet. ' \
                   'Verify their email with a one-time code first, then call this tool again. ' \
                   'If that is not possible, ask whether they want to talk to a support agent.'.freeze

  def perform(tool_context, **params)
    return super unless @custom_tool.requires_email_verification?

    verified_email = stored_verified_email(tool_context.state)
    return failure_result(EMAIL_REQUIRED, tool_context.state) unless verified_email
    return failure_result(other_email_message(verified_email), tool_context.state) if other_email?(params, verified_email)

    # Set last, so a value from the model can never replace the verified email
    email_param = @custom_tool.verified_email_param
    super(tool_context, **(email_param ? params.merge(email_param.to_sym => verified_email) : params))
  end

  private

  def other_email?(params, verified_email)
    emails = params.values.grep(String).flat_map { |value| value.scan(EMAIL_IN_TEXT_PATTERN) }
    # An email at the end of a sentence carries its punctuation, such as a trailing period
    emails.map { |email| email.sub(/[^a-z0-9]+\z/i, '') }.any? { |email| !email.casecmp?(verified_email) }
  end

  def other_email_message(verified_email)
    "This tool can only run for #{verified_email}, the email this customer verified. " \
      'Call it again with that email only. To use another email, verify it with a one-time code first.'
  end
end
