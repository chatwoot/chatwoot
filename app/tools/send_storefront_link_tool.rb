# frozen_string_literal: true

# Tool for generating a storefront link and sharing it with the customer
# Used by AI agent to give customers access to browse products and place orders
#
# Example usage in agent:
#   chat.with_tools([SendStorefrontLinkTool])
#   response = chat.ask("Send the customer a link to browse our products")
#
class SendStorefrontLinkTool < BaseTool
  include Rails.application.routes.url_helpers

  description 'Generate a storefront link so the customer can browse products and place orders. ' \
              'Use this when: ' \
              '1) The customer asks to see or browse your products, ' \
              '2) The customer wants to place an order themselves, ' \
              '3) You want to share a shopping link proactively. ' \
              'The link will NOT be sent automatically — you MUST include the storefront_url from the response in your reply to the customer.'

  def execute
    validate_context!

    if playground_mode?
      return success_response({
                                storefront_url: 'https://example.com/storefront/products?token=playground_token',
                                message: '[Playground] Would generate a storefront link for the customer'
                              })
    end

    validate_catalog_enabled!
    contact = resolve_contact!
    token = create_storefront_token(contact)

    success_response({
                       storefront_url: storefront_products_url(current_account, token: token.token),
                       message: 'Storefront link generated. Include the storefront_url in your message to the customer.'
                     })
  rescue ArgumentError => e
    error_response(e.message)
  rescue StandardError => e
    error_response("Failed to generate storefront link: #{e.message}")
  end

  private

  def validate_catalog_enabled!
    return if current_account.catalog_settings&.enabled?

    raise ArgumentError, 'Catalog is not enabled for this account. Please enable it in Settings → Catalog.'
  end

  def resolve_contact!
    contact = current_contact || current_conversation&.contact
    raise ArgumentError, 'No contact associated with this conversation' unless contact

    contact
  end

  def create_storefront_token(contact)
    StorefrontToken.create!(
      account: current_account,
      contact: contact,
      conversation_id: current_conversation.id
    )
  end
end
