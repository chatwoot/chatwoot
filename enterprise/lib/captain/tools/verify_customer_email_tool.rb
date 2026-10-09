class Captain::Tools::VerifyCustomerEmailTool < Captain::Tools::BasePublicTool
  description 'Verify customer email before accessing private data. Ask for their email, request a code, then verify the code they provide.'
  parameter :operation, type: 'string', description: 'request_code or verify_code'
  parameter :code, type: 'string', description: 'Six-digit code supplied by the customer, only for verify_code. Never guess.', required: false
  parameter :email, type: 'string', description: 'Email supplied by the customer for request_code. Omit to use the contact email.', required: false

  def perform(tool_context, operation:, code: nil, email: nil)
    return 'Customer verification is not enabled.' if @assistant.config['customer_verification_tools'].blank?

    conversation = find_conversation(tool_context.state)
    return 'A real conversation is required for email verification.' unless conversation

    verification = Captain::CustomerEmailVerification.new(assistant: @assistant, conversation: conversation)
    case operation
    when 'request_code' then verification.issue(email: email)
    when 'verify_code' then verification.verify(code)
    else 'Use request_code or verify_code.'
    end
  end
end
