class Enterprise::Billing::V2::InvoicePaymentService < Enterprise::Billing::V2::BaseService
  # Common service for creating invoices with line items and charging immediately
  # Used by both TopupService and ChangePlanService
  #
  # @param line_items [Array<Hash>] Array of line items: [{ amount:, description:, metadata: }]
  # @param description [String] Description for the invoice
  # @param currency [String] Currency code (default: 'usd')
  # @param metadata [Hash] Metadata for the invoice
  # @return [Hash] { success:, invoice_id:, invoice_url:, amount:, status: }

  # Validate that customer has a default payment method
  # @return [Hash, nil] Returns error hash if validation fails, nil if success
  def validate_payment_method
    return { success: false, message: 'No Stripe customer ID found' } if stripe_customer_id.blank?

    customer = Stripe::Customer.retrieve(stripe_customer_id)

    if customer.invoice_settings.default_payment_method.nil? && customer.default_source.nil?
      return {
        success: false,
        message: 'No default payment method found. Please add a default payment method before making a purchase.'
      }
    end

    nil
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to check payment method: #{e.message}")
    { success: false, message: "Error validating payment method: #{e.message}" }
  end

  # Create invoice with line items and charge immediately
  #
  # @param line_items [Array<Hash>] Line items: [{ amount: (cents), description:, metadata: }]
  # @param description [String] Invoice description
  # @param currency [String] Currency (default: 'usd')
  # @param metadata [Hash] Invoice metadata
  # @return [Hash] { success:, invoice_id:, invoice_url:, amount:, status: }
  def create_and_pay_invoice(line_items:, description:, currency: 'usd', metadata: {})
    invoice = create_invoice(stripe_customer_id, currency, description, metadata)
    add_line_items_to_invoice(invoice.id, stripe_customer_id, line_items, currency)
    finalize_and_pay_invoice(invoice.id)
  rescue Stripe::StripeError => e
    Rails.logger.error("Error creating invoice: #{e.message}")
    { success: false, message: "Error creating invoice: #{e.message}" }
  end

  private

  def create_invoice(customer_id, currency, description, metadata)
    Stripe::Invoice.create({
                             customer: customer_id,
                             currency: currency,
                             collection_method: 'charge_automatically',
                             auto_advance: false,
                             description: description,
                             metadata: metadata.stringify_keys
                           })
  end

  def add_line_items_to_invoice(invoice_id, customer_id, line_items, currency)
    line_items.each do |item|
      Stripe::InvoiceItem.create({
                                   customer: customer_id,
                                   amount: item[:amount],
                                   currency: currency,
                                   invoice: invoice_id,
                                   description: item[:description],
                                   metadata: (item[:metadata] || {}).stringify_keys
                                 })
    end
  end

  # Finalize invoice and pay it immediately
  # @param invoice_id [String] Stripe invoice ID
  # @return [Hash] { success:, invoice_id:, invoice_url:, amount:, status: }
  def finalize_and_pay_invoice(invoice_id)
    # Finalize the invoice
    finalized_invoice = Stripe::Invoice.finalize_invoice(
      invoice_id,
      { auto_advance: false }
    )

    # Pay the invoice immediately if not already paid
    if finalized_invoice.status == 'paid'
      build_invoice_response(finalized_invoice)
    else
      paid_invoice = Stripe::Invoice.pay(invoice_id, {})
      build_invoice_response(paid_invoice)
    end
  rescue Stripe::StripeError => e
    Rails.logger.error("Error finalizing/paying invoice: #{e.message}")
    { success: false, message: "Error processing payment: #{e.message}" }
  end

  def build_invoice_response(invoice)
    {
      success: true,
      invoice_id: invoice.id,
      invoice_url: invoice.hosted_invoice_url,
      amount: invoice.total / 100.0,
      status: invoice.status
    }
  end
end
