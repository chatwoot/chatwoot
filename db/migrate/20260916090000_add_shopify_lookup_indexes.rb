class AddShopifyLookupIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :integrations_hooks, :account_id,
              where: "app_id = 'shopify'",
              name: 'index_shopify_hooks_on_account_id',
              algorithm: :concurrently
    add_index :accounts, "(custom_attributes #>> '{shopify_subscription_snapshot,shop_domain}')",
              where: "internal_attributes ->> 'billing_provider' = 'shopify' AND internal_attributes ->> 'signup_source' = 'shopify'",
              name: 'index_shopify_accounts_on_snapshot_shop_domain',
              algorithm: :concurrently
  end
end
