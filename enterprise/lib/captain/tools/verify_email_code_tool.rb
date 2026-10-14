class Captain::Tools::VerifyEmailCodeTool < Captain::Tools::BasePublicTool
  description 'Check the verification code the customer typed, after a code was emailed to them. ' \
              'Pass the code exactly as the customer typed it. Never guess or invent a code.'
  parameter :code, type: 'string', description: 'The 6-digit code the customer typed in the conversation'

  def perform(tool_context, code:)
    contact_inbox = find_contact_inbox(tool_context.state)
    return failure_result('Email verification is not available in this conversation', tool_context.state) unless contact_inbox

    verification = Captain::EmailVerification.new(contact_inbox)
    result = verification.verify(code)
    log_tool_usage('verify_email_code', { contact_inbox_id: contact_inbox.id, result: result })

    case result
    when :verified then verified_message(tool_context, verification.verified_email)
    when :invalid_code then invalid_code_message(verification.attempts_left)
    when :locked then 'Too many wrong codes were entered, so this code no longer works. Send a new code, or offer a support agent.'
    else 'There is no active code. It may have expired. Send a new code first.'
    end
  end

  private

  # The rest of this run reads the state, so the prompt shows the email as verified straight away
  def verified_message(tool_context, email)
    tool_context.state[:verified_email] = email
    hours = Captain::EmailVerification::VERIFIED_TTL.in_hours.to_i
    "Verified. The customer entered the code that was emailed to #{email}, so they can read that mailbox. This stays valid for #{hours} hours."
  end

  def invalid_code_message(attempts_left)
    return 'That code is wrong, and no attempts are left. Send a new code, or ask whether the customer wants a support agent.' if attempts_left.zero?

    "That code is wrong. #{attempts_left} attempts are left. Ask the customer to check the code and type it again."
  end
end
