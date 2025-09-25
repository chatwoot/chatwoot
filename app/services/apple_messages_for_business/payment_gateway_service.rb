class AppleMessagesForBusiness::PaymentGatewayService
  def initialize(channel)
    @channel = channel
  end

  def process_payment(payment_data, transaction_data)
    gateway_type = @channel.payment_processors.dig('primary', 'type') || 'stripe'

    case gateway_type
    when 'stripe'
      process_stripe_payment(payment_data, transaction_data)
    when 'square'
      process_square_payment(payment_data, transaction_data)
    when 'braintree'
      process_braintree_payment(payment_data, transaction_data)
    else
      { error: "Unsupported payment gateway: #{gateway_type}" }
    end
  end

  def handle_webhook(webhook_data, gateway_type)
    case gateway_type
    when 'stripe'
      handle_stripe_webhook(webhook_data)
    when 'square'
      handle_square_webhook(webhook_data)
    when 'braintree'
      handle_braintree_webhook(webhook_data)
    else
      { error: "Unsupported webhook type: #{gateway_type}" }
    end
  end

  def validate_transaction(transaction_id, gateway_type)
    case gateway_type
    when 'stripe'
      validate_stripe_transaction(transaction_id)
    when 'square'
      validate_square_transaction(transaction_id)
    when 'braintree'
      validate_braintree_transaction(transaction_id)
    else
      { error: "Unsupported gateway type: #{gateway_type}" }
    end
  end

  private

  # Stripe Integration
  def process_stripe_payment(payment_data, transaction_data)
    require 'stripe'

    Stripe.api_key = @channel.payment_processors.dig('stripe', 'secret_key') ||
                     ENV['STRIPE_SECRET_KEY']

    begin
      # Create a payment intent
      intent = Stripe::PaymentIntent.create({
        amount: (transaction_data[:total][:amount].to_f * 100).to_i, # Convert to cents
        currency: transaction_data[:total][:currency_code].downcase,
        payment_method_types: ['card'],
        payment_method_data: {
          type: 'card',
          card: {
            token: extract_stripe_token(payment_data)
          }
        },
        confirmation_method: 'manual',
        confirm: true,
        description: "Apple Messages payment for #{@channel.name}",
        metadata: {
          channel_id: @channel.id,
          msp_id: @channel.msp_id,
          apple_pay: 'true'
        },
        shipping: format_stripe_shipping(payment_data[:shipping_contact]),
        receipt_email: payment_data[:billing_contact][:email_address]
      })

      {
        success: true,
        transaction_id: intent.id,
        status: intent.status,
        amount: intent.amount / 100.0,
        currency: intent.currency.upcase,
        gateway: 'stripe'
      }
    rescue Stripe::StripeError => e
      {
        error: "Stripe payment failed: #{e.message}",
        gateway: 'stripe'
      }
    end
  end

  def extract_stripe_token(payment_data)
    # Extract relevant payment information for Stripe
    # This would typically involve the decrypted payment token
    {
      number: payment_data[:application_primary_account_number],
      exp_month: payment_data[:application_expiry_date][0..1],
      exp_year: "20#{payment_data[:application_expiry_date][2..3]}",
      cvc: payment_data[:device_manufacturer_identifier] # This is a simplified approach
    }
  end

  def format_stripe_shipping(shipping_contact)
    return nil unless shipping_contact

    {
      name: "#{shipping_contact[:given_name]} #{shipping_contact[:family_name]}",
      phone: shipping_contact[:phone_number],
      address: {
        line1: shipping_contact[:address_lines]&.first,
        line2: shipping_contact[:address_lines]&.second,
        city: shipping_contact[:locality],
        state: shipping_contact[:administrative_area],
        postal_code: shipping_contact[:postal_code],
        country: shipping_contact[:country_code]
      }
    }
  end

  def handle_stripe_webhook(webhook_data)
    require 'stripe'

    Stripe.api_key = @channel.payment_processors.dig('stripe', 'secret_key') ||
                     ENV['STRIPE_SECRET_KEY']

    begin
      event = Stripe::Webhook.construct_event(
        webhook_data[:payload],
        webhook_data[:signature],
        @channel.payment_processors.dig('stripe', 'webhook_secret') || ENV['STRIPE_WEBHOOK_SECRET']
      )

      case event.type
      when 'payment_intent.succeeded'
        handle_payment_success(event.data.object, 'stripe')
      when 'payment_intent.payment_failed'
        handle_payment_failure(event.data.object, 'stripe')
      when 'payment_intent.canceled'
        handle_payment_canceled(event.data.object, 'stripe')
      end

      { status: 'processed' }
    rescue Stripe::SignatureVerificationError
      { error: 'Invalid webhook signature' }
    end
  end

  def validate_stripe_transaction(transaction_id)
    require 'stripe'

    Stripe.api_key = @channel.payment_processors.dig('stripe', 'secret_key') ||
                     ENV['STRIPE_SECRET_KEY']

    begin
      intent = Stripe::PaymentIntent.retrieve(transaction_id)

      {
        valid: true,
        status: intent.status,
        amount: intent.amount / 100.0,
        currency: intent.currency.upcase,
        created: Time.at(intent.created)
      }
    rescue Stripe::StripeError => e
      { valid: false, error: e.message }
    end
  end

  # Square Integration
  def process_square_payment(payment_data, transaction_data)
    require 'squareup'

    client = Squareup::Client.new(
      access_token: @channel.payment_processors.dig('square', 'access_token') ||
                    ENV['SQUARE_ACCESS_TOKEN'],
      environment: @channel.payment_processors.dig('square', 'environment') || 'sandbox'
    )

    begin
      payments_api = client.payments

      request_body = {
        source_id: extract_square_source_id(payment_data),
        amount_money: {
          amount: (transaction_data[:total][:amount].to_f * 100).to_i,
          currency: transaction_data[:total][:currency_code]
        },
        idempotency_key: SecureRandom.uuid,
        app_fee_money: nil,
        autocomplete: true,
        order_id: nil,
        customer_id: nil,
        location_id: @channel.payment_processors.dig('square', 'location_id'),
        reference_id: "apple_pay_#{@channel.msp_id}_#{Time.current.to_i}",
        note: "Apple Messages payment for #{@channel.name}",
        billing_address: format_square_address(payment_data[:billing_contact]),
        shipping_address: format_square_address(payment_data[:shipping_contact])
      }

      result = payments_api.create_payment(body: request_body)

      if result.success?
        payment = result.data.payment
        {
          success: true,
          transaction_id: payment.id,
          status: payment.status,
          amount: payment.amount_money.amount / 100.0,
          currency: payment.amount_money.currency,
          gateway: 'square'
        }
      else
        {
          error: "Square payment failed: #{result.errors.first&.detail}",
          gateway: 'square'
        }
      end
    rescue StandardError => e
      {
        error: "Square payment error: #{e.message}",
        gateway: 'square'
      }
    end
  end

  def extract_square_source_id(payment_data)
    # Create a payment source from Apple Pay data
    # This is simplified - actual implementation would need proper token conversion
    payment_data[:application_primary_account_number]
  end

  def format_square_address(contact)
    return nil unless contact

    {
      address_line_1: contact[:address_lines]&.first,
      address_line_2: contact[:address_lines]&.second,
      locality: contact[:locality],
      administrative_district_level_1: contact[:administrative_area],
      postal_code: contact[:postal_code],
      country: contact[:country_code]
    }
  end

  # Braintree Integration
  def process_braintree_payment(payment_data, transaction_data)
    require 'braintree'

    Braintree::Configuration.environment = @channel.payment_processors.dig('braintree', 'environment')&.to_sym || :sandbox
    Braintree::Configuration.merchant_id = @channel.payment_processors.dig('braintree', 'merchant_id') || ENV['BRAINTREE_MERCHANT_ID']
    Braintree::Configuration.public_key = @channel.payment_processors.dig('braintree', 'public_key') || ENV['BRAINTREE_PUBLIC_KEY']
    Braintree::Configuration.private_key = @channel.payment_processors.dig('braintree', 'private_key') || ENV['BRAINTREE_PRIVATE_KEY']

    begin
      result = Braintree::Transaction.sale(
        amount: transaction_data[:total][:amount].to_f,
        payment_method_nonce: extract_braintree_nonce(payment_data),
        options: {
          submit_for_settlement: true
        },
        billing: format_braintree_address(payment_data[:billing_contact]),
        shipping: format_braintree_address(payment_data[:shipping_contact])
      )

      if result.success?
        transaction = result.transaction
        {
          success: true,
          transaction_id: transaction.id,
          status: transaction.status,
          amount: transaction.amount.to_f,
          currency: transaction.currency_iso_code,
          gateway: 'braintree'
        }
      else
        {
          error: "Braintree payment failed: #{result.message}",
          gateway: 'braintree'
        }
      end
    rescue StandardError => e
      {
        error: "Braintree payment error: #{e.message}",
        gateway: 'braintree'
      }
    end
  end

  def extract_braintree_nonce(payment_data)
    # Convert Apple Pay data to Braintree payment method nonce
    # This would typically involve Braintree's Apple Pay integration
    payment_data[:payment_method_nonce] || 'fake-apple-pay-visa-nonce'
  end

  def format_braintree_address(contact)
    return nil unless contact

    {
      first_name: contact[:given_name],
      last_name: contact[:family_name],
      street_address: contact[:address_lines]&.first,
      extended_address: contact[:address_lines]&.second,
      locality: contact[:locality],
      region: contact[:administrative_area],
      postal_code: contact[:postal_code],
      country_code_alpha2: contact[:country_code]
    }
  end

  # Common webhook handlers
  def handle_payment_success(payment_object, gateway)
    # Trigger success notification
    AppleMessagesForBusiness::PaymentCompleteJob.perform_later(
      channel_id: @channel.id,
      transaction_id: payment_object.id,
      status: 'success',
      gateway: gateway
    )
  end

  def handle_payment_failure(payment_object, gateway)
    # Trigger failure notification
    AppleMessagesForBusiness::PaymentCompleteJob.perform_later(
      channel_id: @channel.id,
      transaction_id: payment_object.id,
      status: 'failed',
      gateway: gateway
    )
  end

  def handle_payment_canceled(payment_object, gateway)
    # Trigger cancellation notification
    AppleMessagesForBusiness::PaymentCompleteJob.perform_later(
      channel_id: @channel.id,
      transaction_id: payment_object.id,
      status: 'canceled',
      gateway: gateway
    )
  end
end