# A product from a business's catalog, as WhatsApp carries it in a message: on its own
# (a card of kind product) or quoted by a question asked from the catalog. Every member is
# what WhatsApp sent, so an absent price is absent and never zero. An empty product is one
# WhatsApp sent nothing readable about, and it is still a product the bubble has to show.
class Whatsapp::Session::Model::Product < Data.define(
  :id, :title, :description, :price_1000, :sale_price_1000, :currency, :retailer_id, :url,
  :image_count, :owner, :thumbnail
)
  include Whatsapp::Session::Model::Serializable

  coerce owner: Whatsapp::Session::Model::Address

  # The price the customer pays: the sale price when the business set one.
  def current_price_1000 = sale_price_1000 || price_1000
end
