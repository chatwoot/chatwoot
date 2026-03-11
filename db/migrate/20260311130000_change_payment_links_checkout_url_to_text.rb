class ChangePaymentLinksCheckoutUrlToText < ActiveRecord::Migration[7.1]
  def up
    change_column :payment_links, :checkout_url, :text
  end

  def down
    change_column :payment_links, :checkout_url, :string
  end
end
