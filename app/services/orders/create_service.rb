class Orders::CreateService
  include PaymentCustomerSanitizable

  attr_reader :conversation, :creator, :items, :currency, :account, :catalog_settings

  # @param conversation [Conversation] The conversation to create the order for
  # @param items [Array<Hash>] Array of {product_id:, quantity:} hashes
  # @param creator [User, Aloo::Assistant] The user or assistant creating the order
  # @param delivery_address [Hash] Optional delivery address
  def initialize(conversation:, items:, creator: Current.user, send_message: true, delivery_address: {})
    @conversation = conversation
    @creator = creator
    @items = items
    @send_message = send_message
    @delivery_address = delivery_address
    @account = conversation.account
    @catalog_settings = account.catalog_settings
    @currency = @catalog_settings&.currency || 'SAR'
  end

  def perform
    validate_catalog_enabled!
    validate_payment_gateway!
    validate_items!

    order = create_order_record

    begin
      case payment_provider
      when 'payzah'
        response = call_payzah_api(order.external_payment_id, order.total)
        update_with_payzah_data(order, response)
      when 'tap'
        response = call_tap_api(order.external_payment_id, order.total)
        update_with_tap_data(order, response)
      end

      if @send_message
        message = create_message(order)
        order.update!(message: message)
      end

      Rails.logger.info("Order created successfully: #{order.id}")
      order
    rescue StandardError => e
      Rails.logger.error("Order creation failed: #{e.message}")
      order.mark_as_failed!({ error: e.message, failed_at: Time.current.iso8601 })
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
    raise ArgumentError, 'Order must have at least one item' if items.blank?

    items.each do |item|
      product = Product.find_by(id: item[:product_id], account_id: account.id)
      raise ArgumentError, "Product #{item[:product_id]} not found" unless product
      raise ArgumentError, 'Quantity must be positive' if item[:quantity].to_i <= 0
      raise ArgumentError, I18n.t('errors.products.out_of_stock', title: product.title_en) unless product.in_stock?(item[:quantity].to_i)
    end
  end

  def create_order_record
    order = Order.new(
      account: account,
      conversation: conversation,
      contact: conversation.contact,
      created_by: creator,
      currency: currency,
      status: :initiated,
      provider: payment_provider,
      payment_url: '',
      subtotal: 0,
      total: 0,
      delivery_address: @delivery_address,
      payload: {
        customer_data: customer_data,
        initiated_at: Time.current.iso8601
      }
    )

    items.each do |item|
      product = Product.find(item[:product_id])
      order.order_items.build(
        product: product,
        quantity: item[:quantity],
        unit_price: product.price
      )
    end

    order.save!
    deduct_stock_for_items!
    order
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

  def update_with_payzah_data(order, payzah_response)
    order.update!(
      payment_url: payzah_response['transit_url'],
      status: :pending,
      payload: order.payload.merge(
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

  def update_with_tap_data(order, tap_response)
    order.update!(
      payment_url: tap_response['url'],
      external_payment_id: tap_response['id'],
      status: :pending,
      payload: order.payload.merge(
        tap_invoice_id: tap_response['id'],
        tap_response: tap_response.to_h,
        tap_called_at: Time.current.iso8601
      )
    )
  end

  def create_message(order)
    Messages::MessageBuilder.new(creator, conversation, {
                                   content: build_message_content(order),
                                   message_type: :outgoing,
                                   content_type: :cart,
                                   private: false,
                                   content_attributes: {
                                     data: build_message_data(order)
                                   }
                                 }).perform
  end

  def build_message_content(order)
    lines = []
    lines << "*🙏🏻 Thank you for shopping at #{account.name}. Kindly find your selected products & invoice* ##{order.external_payment_id} 🧾:"
    lines << '_________'
    lines << ''

    order.order_items.includes(:product).each do |item|
      lines << "#{item.quantity}x - #{item.product.title_en} #{format_price(item.total_price)} #{currency}"
    end

    lines << ''
    lines << '_________'
    lines << ''
    lines << "*Total*: #{format_price(order.total)} #{currency} *"
    lines << '_________'
    lines << ''
    lines << "To pay, kindly click on the link 🔗 : #{order.payment_url}"

    lines.join("\n")
  end

  def format_price(amount)
    format('%.3f', amount)
  end

  def build_message_data(order)
    {
      order_id: order.id,
      external_payment_id: order.external_payment_id,
      payment_url: order.payment_url,
      preview_url: order.preview_url,
      currency: currency,
      subtotal: order.subtotal.to_f,
      total: order.total.to_f,
      status: order.status,
      items: order.order_items.includes(:product).map do |item|
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

  def deduct_stock_for_items!
    items.each do |item|
      product = Product.find(item[:product_id])
      product.deduct_stock!(item[:quantity].to_i) unless product.stock.nil?
    end
  end

  def customer_data
    @customer_data ||= {
      name: sanitize_customer_name(conversation.contact&.name),
      email: conversation.contact&.email,
      phone: conversation.contact&.phone_number
    }.compact
  end
end
