class AddCaptainToolCatalogIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  CATALOG_PROVIDERS = %w[stripe shopify linear slack].freeze

  def change
    add_custom_tool_indexes
    add_integration_hook_index
  end

  private

  def add_custom_tool_indexes
    add_index :captain_custom_tools, [:account_id, :source_kind],
              algorithm: :concurrently,
              name: 'idx_captain_tools_account_source'
    add_index :captain_custom_tools, [:account_id, :provider_key],
              algorithm: :concurrently,
              where: 'provider_key IS NOT NULL',
              name: 'idx_captain_tools_account_provider'
    add_index :captain_custom_tools, :integration_hook_id,
              algorithm: :concurrently,
              name: 'idx_captain_tools_integration_hook'
    add_index :captain_custom_tools, [:account_id, :provider_key, :template_key],
              algorithm: :concurrently,
              unique: true,
              where: "source_kind = 'catalog'",
              name: 'idx_captain_tools_catalog_template'
  end

  def add_integration_hook_index
    add_index :integrations_hooks, [:account_id, :app_id],
              algorithm: :concurrently,
              unique: true,
              where: "hook_type = 0 AND app_id IN (#{quoted_catalog_providers})",
              name: 'idx_integrations_hooks_catalog_provider'
  end

  def quoted_catalog_providers
    CATALOG_PROVIDERS.map { |provider| connection.quote(provider) }.join(', ')
  end
end
