class AddUniqueIndexesToShopifyHooks < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_duplicate_shopify_hooks!(
      partition_by: 'LOWER(reference_id)',
      constraint_name: 'store domain'
    )
    remove_duplicate_shopify_hooks!(
      partition_by: 'account_id',
      constraint_name: 'account'
    )
    add_unique_shopify_indexes
  end

  def down
    remove_index :integrations_hooks,
                 name: 'index_shopify_hooks_on_lower_reference_id',
                 algorithm: :concurrently,
                 if_exists: true
    remove_index :integrations_hooks,
                 name: 'index_shopify_hooks_on_account_id',
                 algorithm: :concurrently,
                 if_exists: true
  end

  private

  def add_unique_shopify_indexes
    add_index :integrations_hooks,
              :account_id,
              unique: true,
              where: "app_id = 'shopify'",
              name: 'index_shopify_hooks_on_account_id',
              algorithm: :concurrently,
              if_not_exists: true
    add_index :integrations_hooks,
              'LOWER(reference_id)',
              unique: true,
              where: "app_id = 'shopify'",
              name: 'index_shopify_hooks_on_lower_reference_id',
              algorithm: :concurrently,
              if_not_exists: true
  end

  def remove_duplicate_shopify_hooks!(partition_by:, constraint_name:)
    duplicate_hooks = select_all(duplicate_shopify_hooks_sql(partition_by))
    return if duplicate_hooks.empty?

    say "Removing #{duplicate_hooks.count} duplicate Shopify hooks for the #{constraint_name} constraint"
    duplicate_hooks.each do |hook|
      say "Removing hook #{hook['id']} from account #{hook['account_id']} for #{hook['reference_id']}"
    end
    execute <<~SQL.squish
      DELETE FROM integrations_hooks
      WHERE id IN (
        SELECT id
        FROM (
          #{ranked_shopify_hooks_sql(partition_by)}
        ) ranked_hooks
        WHERE duplicate_rank > 1
      )
    SQL
  end

  def duplicate_shopify_hooks_sql(partition_by)
    <<~SQL.squish
      SELECT id, account_id, reference_id
      FROM (
        #{ranked_shopify_hooks_sql(partition_by)}
      ) ranked_hooks
      WHERE duplicate_rank > 1
      ORDER BY id
    SQL
  end

  def ranked_shopify_hooks_sql(partition_by)
    <<~SQL.squish
      SELECT id,
             account_id,
             reference_id,
             ROW_NUMBER() OVER (
               PARTITION BY #{partition_by}
               ORDER BY updated_at DESC, id DESC
             ) AS duplicate_rank
      FROM integrations_hooks
      WHERE app_id = 'shopify'
    SQL
  end
end
