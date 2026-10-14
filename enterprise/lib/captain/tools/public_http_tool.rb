# A custom tool in a conversation where a customer is the user. Every verified value it needs must be stored for this
# customer, and the verified email is the only email the request can carry.
class Captain::Tools::PublicHttpTool < Captain::Tools::HttpTool
  EMAIL_IN_TEXT_PATTERN = /[^\s@<>"',;:()]+@[^\s@<>"',;:()]+/
  EMAIL_REQUIRED = 'This tool needs a verified email, and this customer has not verified an email yet. ' \
                   'Verify their email with a one-time code first, then call this tool again. ' \
                   'If that is not possible, ask whether they want to talk to a support agent.'.freeze

  def perform(tool_context, **params)
    return super if required_sources.empty?

    verified_values = stored_verified_values(tool_context.state)
    reason = refusal(params, verified_values)
    return failure_result(reason, tool_context.state) if reason

    super(tool_context, **@custom_tool.with_verified_values(params, verified_values).symbolize_keys)
  end

  private

  def refusal(params, verified_values)
    missing = required_sources - verified_values.keys
    return EMAIL_REQUIRED if missing.include?('verified.email')

    verified_email = verified_values['verified.email']
    other_email_message(verified_email) if verified_email && other_email?(params, verified_email)
  end

  def required_sources
    @custom_tool.verified_sources | (@custom_tool.requires_email_verification? ? ['verified.email'] : [])
  end

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
