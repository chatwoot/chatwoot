class Captain::Tools::SendEmailVerificationCodeTool < Captain::Tools::BasePublicTool
  description 'Email a 6-digit verification code to the customer, to prove they own an email address before account-specific ' \
              'data is shared or changed. Confirm the exact email address with the customer before calling this.'
  parameter :email, type: 'string', description: 'The email address the customer confirmed they want the code sent to'

  def perform(tool_context, email:)
    contact_inbox = find_contact_inbox(tool_context.state)
    return failure_result('Email verification is not available in this conversation', tool_context.state) unless contact_inbox

    log_tool_usage('send_email_verification_code', { contact_inbox_id: contact_inbox.id })

    case Captain::EmailVerification.new(contact_inbox).send_code(email)
    when :sent then sent_message(email)
    when :already_verified then 'This email address is already verified for this customer. No code was sent. Continue with their request.'
    when :rate_limited then 'Too many codes were sent recently. Do not try again now. Ask whether the customer wants to talk to a support agent.'
    else 'That is not a valid email address. Ask the customer for the correct email address.'
    end
  end

  private

  def sent_message(email)
    minutes = Captain::EmailVerification::CODE_TTL.in_minutes.to_i
    "A #{Captain::EmailVerification::CODE_LENGTH}-digit code was emailed to #{email.to_s.strip.downcase}. It expires in #{minutes} minutes. " \
      'Ask the customer to type the code here, then check it with the verify email code tool. ' \
      'If the code does not arrive, ask whether they want to talk to a support agent.'
  end
end
