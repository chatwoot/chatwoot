# An order placed from a business's catalog. Amounts are integers in thousandths of the
# currency's unit. `items` comes from WhatsApp's catalog API and is absent when it did not
# answer; an item's price is absent when the connector could not prove its scale. `title`
# is the seller account's name, which WhatsApp does not show on the card.
class Whatsapp::Session::Model::Order < Data.define(
  :id, :title, :status, :surface, :item_count, :total_1000, :currency, :subtotal_1000,
  :seller, :thumbnail, :items
)
  include Whatsapp::Session::Model::Serializable

  class Item < Data.define(:product_id, :name, :quantity, :price_1000, :currency, :variant, :image)
    include Whatsapp::Session::Model::Serializable
  end

  coerce seller: Whatsapp::Session::Model::Address, items: [Item]

  # WhatsApp counts units, not lines (2 shirts and a mug are 3 items), and the items carry
  # the same count when the summary does not.
  def units = item_count || items&.sum { |item| item.quantity.to_i }
end
