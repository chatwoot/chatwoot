class AddUniqueIndexesToShopifyHooks < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :integrations_hooks,
              :account_id,
              unique: true,
              where: "app_id = 'shopify'",
              name: 'index_shopify_hooks_on_account_id',
              algorithm: :concurrently
    add_index :integrations_hooks,
              'LOWER(reference_id)',
              unique: true,
              where: "app_id = 'shopify'",
              name: 'index_shopify_hooks_on_lower_reference_id',
              algorithm: :concurrently
  end
end
