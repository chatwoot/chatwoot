class Carts::CreateService
  include PaymentCustomerSanitizable

  attr_reader :conversation, :user, :items, :currency, :account, :catalog_settings

  def initialize(conversation:, items:, user: Current.user)
    @conversation = conversation
    @user = user
    @items = items
    @account = conversation.account
    @catalog_settings = account.catalog_settings
    @currency = @catalog_settings&.currency || 'SAR'
  end

  def perform
    validate_catalog_enabled!
    validate_payment_gateway!
    validate_items!

    cart = create_cart_record

    begin
      case payment_provider
      when 'payzah'
        response = call_payzah_api(cart.external_payment_id, cart.total)
        update_with_payzah_data(cart, response)
      when 'tap'
        response = call_tap_api(cart.external_payment_id, cart.total)
        update_with_tap_data(cart, response)
      end

      message = create_message(cart)
      cart.update!(message: message)

      Rails.logger.info("Cart created successfully: #{cart.id}")
      cart
    rescue StandardError => e
      Rails.logger.error("Cart creation failed: #{e.message}")
      cart.mark_as_failed!({ error: e.message, failed_at: Time.current.iso8601 })
      raise
    end
  end

  private

  def validate_catalog_enabled!
    return if catalog_settings&.enabled?

    raise ArgumentError, 'Catalog is not enabled for this account.'
  end

  def validate_payment_gateway!
    return if payment_provider.present?

    raise ArgumentError, 'No payment gateway configured. Please select a payment provider in Settings → Catalog.'
  end

  def payment_provider
    catalog_settings&.payment_provider
  end

  def validate_items!
    raise ArgumentError, 'Cart must have at least one item' if items.blank?

    items.each do |item|
      product = Product.find_by(id: item[:product_id], account_id: account.id)
      raise ArgumentError, "Product #{item[:product_id]} not found" unless product
      raise ArgumentError, 'Quantity must be positive' if item[:quantity].to_i <= 0
    end
  end

  def create_cart_record
    cart = Cart.new(
      account: account,
      conversation: conversation,
      contact: conversation.contact,
      created_by: user,
      currency: currency,
      status: :initiated,
      provider: payment_provider,
      payment_url: '',
      subtotal: 0,
      total: 0,
      payload: {
        customer_data: customer_data,
        initiated_at: Time.current.iso8601
      }
    )

    items.each do |item|
      product = Product.find(item[:product_id])
      cart.cart_items.build(
        product: product,
        quantity: item[:quantity],
        unit_price: product.price
      )
    end

    cart.save!
    cart
  end

  def call_payzah_api(trackid, amount)
    Payzah::CreatePaymentLinkService.new(
      trackid: trackid,
      amount: amount,
      currency: currency,
      customer: customer_data,
      api_key: account.payzah_settings.api_key
    ).perform
  end

  def update_with_payzah_data(cart, payzah_response)
    cart.update!(
      payment_url: payzah_response['transit_url'],
      status: :pending,
      payload: cart.payload.merge(
        payzah_payment_id: payzah_response['PaymentID'],
        payzah_response: payzah_response.to_h,
        payzah_called_at: Time.current.iso8601
      )
    )
  end

  def call_tap_api(reference_id, amount)
    Tap::CreateInvoiceService.new(
      reference_id: reference_id,
      amount: amount,
      currency: currency,
      customer: customer_data,
      secret_key: account.tap_settings.secret_key
    ).perform
  end

  def update_with_tap_data(cart, tap_response)
    cart.update!(
      payment_url: tap_response['url'],
      status: :pending,
      payload: cart.payload.merge(
        tap_invoice_id: tap_response['id'],
        tap_response: tap_response.to_h,
        tap_called_at: Time.current.iso8601
      )
    )
  end

  def create_message(cart)
    Messages::MessageBuilder.new(user, conversation, {
                                   content: build_message_content(cart),
                                   message_type: :outgoing,
                                   content_type: :cart,
                                   private: false,
                                   content_attributes: {
                                     data: build_message_data(cart)
                                   }
                                 }).perform
  end

  def build_message_content(cart)
    lines = []
    lines << "*🙏🏻 Thank you for shopping at #{account.name}. Kindly find your selected products & invoice* ##{cart.external_payment_id} 🧾:"
    lines << '_________'
    lines << ''

    cart.cart_items.includes(:product).each do |item|
      lines << "#{item.quantity}x - #{item.product.title_en} #{format_price(item.total_price)} #{currency}"
    end

    lines << ''
    lines << '_________'
    lines << ''
    lines << "*Total*: #{format_price(cart.total)} #{currency} *"
    lines << '_________'
    lines << ''
    lines << "To pay, kindly click on the link 🔗 : #{cart.payment_url}"

    lines.join("\n")
  end

  def format_price(amount)
    format('%.3f', amount)
  end

  def build_message_data(cart)
    {
      cart_id: cart.id,
      external_payment_id: cart.external_payment_id,
      payment_url: cart.payment_url,
      preview_url: cart.preview_url,
      currency: currency,
      subtotal: cart.subtotal.to_f,
      total: cart.total.to_f,
      status: cart.status,
      items: cart.cart_items.includes(:product).map do |item|
        {
          product_id: item.product_id,
          title_en: item.product.title_en,
          title_ar: item.product.title_ar,
          quantity: item.quantity,
          unit_price: item.unit_price.to_f,
          total_price: item.total_price.to_f,
          image_url: item.product.image_url
        }
      end
    }
  end

  def customer_data
    @customer_data ||= {
      name: sanitize_customer_name(conversation.contact&.name),
      email: conversation.contact&.email,
      phone: conversation.contact&.phone_number
    }.compact
  end
end
