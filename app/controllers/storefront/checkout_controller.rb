class Storefront::CheckoutController < Storefront::BaseController
  before_action :ensure_catalog_enabled!
  before_action :ensure_cart_not_empty, only: [:show, :create]

  # GET /store/:account_id/checkout
  def show
    @cart_items = load_cart_items
    @contact = current_contact
    @currency = catalog_settings.currency
    @address = current_contact.additional_attributes&.dig('address') || {}
    @cart_subtotal = @cart_items.sum(&:total_price)
  end

  # POST /store/:account_id/checkout
  def create
    update_contact_info!
    cart = create_cart_and_pay!
    clear_session_cart!

    redirect_to cart.payment_url, allow_other_host: true
  rescue StandardError => e
    flash[:error] = e.message
    redirect_to storefront_checkout_path(@account, token: storefront_token_param)
  end

  private

  def ensure_cart_not_empty
    return if session_cart.present?

    redirect_to storefront_products_path(@account, token: storefront_token_param)
  end

  def update_contact_info!
    contact_attrs = checkout_params
    current_contact.assign_attributes(
      name: contact_attrs[:name].presence || current_contact.name,
      email: contact_attrs[:email].presence || current_contact.email,
      phone_number: contact_attrs[:phone_number].presence || current_contact.phone_number
    )
    current_contact.save! if current_contact.changed?

    save_address!(contact_attrs[:address]) if contact_attrs[:address].present?
  end

  def save_address!(address_params)
    merged = current_contact.additional_attributes.merge('address' => address_params.to_h)
    current_contact.update!(additional_attributes: merged)
  end

  def create_cart_and_pay!
    conversation = find_or_create_conversation!
    items = session_cart.map { |pid, qty| { product_id: pid.to_i, quantity: qty.to_i } }

    Orders::CreateService.new(
      conversation: conversation,
      items: items,
      creator: storefront_creator
    ).perform
  end

  def find_or_create_conversation!
    return @storefront_token.conversation if @storefront_token.conversation.present?

    current_contact.conversations
                   .where(account: @account)
                   .where.not(status: :resolved)
                   .order(created_at: :desc)
                   .first || create_new_conversation!
  end

  def create_new_conversation!
    inbox = storefront_inbox
    contact_inbox = ContactInbox.find_or_create_by!(contact: current_contact, inbox: inbox) do |ci|
      ci.source_id = SecureRandom.uuid
    end

    Conversation.create!(
      account: @account,
      inbox: inbox,
      contact: current_contact,
      contact_inbox: contact_inbox
    )
  end

  def storefront_inbox
    @account.inboxes.find_by(channel_type: 'Channel::Api') || @account.inboxes.first
  end

  def storefront_creator
    @account.account_users.find_by(role: :administrator)&.user || @account.account_users.first&.user
  end

  def checkout_params
    params.require(:contact).permit(:name, :email, :phone_number, address: [:street, :city, :state, :postal_code, :country])
  end

  def session_key
    "storefront_cart_#{@account.id}_#{current_contact.id}"
  end

  def session_cart
    session[session_key] || {}
  end

  def clear_session_cart!
    session.delete(session_key)
  end

  def load_cart_items
    cart_data = session_cart
    return [] if cart_data.blank?

    product_ids = cart_data.keys.map(&:to_i)
    products = @account.products.where(id: product_ids).index_by(&:id)

    cart_data.filter_map do |product_id, quantity|
      product = products[product_id.to_i]
      next unless product

      OpenStruct.new(product: product, quantity: quantity.to_i, total_price: product.price * quantity.to_i)
    end
  end
end
