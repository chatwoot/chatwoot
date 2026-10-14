class AddShopifyHookDomainLookupIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :integrations_hooks, 'LOWER(reference_id)',
              where: "app_id = 'shopify'",
              name: 'index_shopify_hooks_on_lower_reference_id',
              algorithm: :concurrently
  end
end
