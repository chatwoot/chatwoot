# Shared boundary for protected custom tools. Adapters translate a verified
# identity into provider-scoped parameters; the model cannot select the identity.
class Captain::ToolCustomerAuthorization
  class Unauthorized < StandardError; end

  def initialize(assistant:, tool:, state:)
    @assistant = assistant
    @tool = tool
    @state = state || {}
  end

  def parameters(params)
    adapter = @assistant.config.fetch('customer_verification_tools', {})[@tool.slug]
    return params unless adapter

    conversation = @assistant.account.conversations.find_by(id: @state.dig(:conversation, :id))
    raise Unauthorized, 'A real conversation is required for customer verification.' unless conversation

    email = Captain::CustomerEmailVerification.new(assistant: @assistant, conversation: conversation).verified_email
    raise Unauthorized, 'Use verify_customer_email to verify the customer email before accessing private data.' if email.blank?

    case adapter
    when 'stripe' then Captain::StripeToolAuthorization.new(tool: @tool, email: email).parameters
    else raise Unauthorized, 'This protected tool has no supported customer authorization adapter.'
    end
  end
end
