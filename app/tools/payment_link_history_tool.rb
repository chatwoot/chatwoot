# frozen_string_literal: true

# Tool for retrieving a contact's payment link history
# Used by AI agent to answer questions about past payments and payment status
#
# Example usage in agent:
#   chat.with_tools([PaymentLinkHistoryTool])
#   response = chat.ask("Has the customer's payment been completed?")
#
class PaymentLinkHistoryTool < BaseTool
  description 'Retrieve the payment link history for the current customer. ' \
              'Use this when: ' \
              '1) The customer asks about their payment history or payment status, ' \
              '2) The customer wants to know if their payment went through, ' \
              '3) You need to look up a payment link for the customer. ' \
              'Returns the most recent payment links with their status.'

  param :status, type: :string,
                 desc: 'Optional filter by payment status: initiated, pending, paid, failed, expired, or cancelled',
                 required: false

  def execute(status: nil)
    validate_context!

    if playground_mode?
      return success_response({
                                message: '[Playground] Would retrieve payment link history for the customer',
                                payment_links: []
                              })
    end

    contact = resolve_contact!
    payment_links = fetch_payment_links(contact, status)

    success_response({
                       contact_name: contact.name,
                       payment_links: payment_links.map { |pl| format_payment_link(pl) }
                     })
  rescue ArgumentError => e
    error_response(e.message)
  rescue StandardError => e
    error_response("Failed to retrieve payment link history: #{e.message}")
  end

  private

  def resolve_contact!
    contact = current_contact || current_conversation&.contact
    raise ArgumentError, 'No contact associated with this conversation' unless contact

    contact
  end

  def fetch_payment_links(contact, status)
    scope = current_account.payment_links.for_contact(contact.id).recent
    scope = scope.by_status(status) if status.present?
    scope.limit(10)
  end

  def format_payment_link(payment_link)
    {
      id: payment_link.id,
      external_payment_id: payment_link.external_payment_id,
      status: payment_link.status,
      amount: payment_link.amount.to_f,
      currency: payment_link.currency,
      provider: payment_link.provider,
      payment_url: payment_link.payment_url,
      created_at: payment_link.created_at.iso8601
    }
  end
end
