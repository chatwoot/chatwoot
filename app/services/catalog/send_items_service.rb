class Catalog::SendItemsService
  attr_reader :conversation, :user, :product_ids, :account

  def initialize(conversation:, product_ids:, user: Current.user)
    @conversation = conversation
    @user = user
    @product_ids = product_ids
    @account = conversation.account
  end

  def perform
    validate_catalog_enabled!
    products = fetch_products

    raise ArgumentError, 'No products found' if products.empty?

    message_content = build_message_content(products)
    create_message(message_content, products)
  end

  private

  def validate_catalog_enabled!
    catalog_settings = account.catalog_settings
    raise ArgumentError, 'Catalog is not enabled' unless catalog_settings&.enabled?
  end

  def fetch_products
    account.products.where(id: product_ids)
  end

  def build_message_content(products)
    currency = account.catalog_settings&.currency || 'SAR'
    lines = []
    products.each do |product|
      lines << "#{product.title_en}"
      lines << "Price: #{product.price} #{currency}"
      lines << product.description_en if product.description_en.present?
      lines << ''
    end
    lines.join("\n").strip
  end

  def create_message(content, products)
    currency = account.catalog_settings&.currency || 'SAR'
    Messages::MessageBuilder.new(user, conversation, {
                                   content: content,
                                   message_type: :outgoing,
                                   content_type: :text,
                                   private: false,
                                   content_attributes: {
                                     catalog_items: products.map do |p|
                                       { id: p.id, title: p.title_en, price: p.price, currency: currency }
                                     end
                                   }
                                 }).perform
  end
end
