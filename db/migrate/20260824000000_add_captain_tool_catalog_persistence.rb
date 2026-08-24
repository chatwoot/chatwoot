class AddCaptainToolCatalogPersistence < ActiveRecord::Migration[7.1]
  def change
    add_catalog_fields_to_custom_tools
    add_refresh_token_to_integration_hooks
    create_tool_catalog_installations
    add_tool_catalog_installation_indexes
    add_catalog_constraints
  end

  private

  def add_catalog_fields_to_custom_tools
    change_column_null :captain_custom_tools, :endpoint_url, true
    change_column_null :captain_custom_tools, :auth_config, false, {}

    change_table :captain_custom_tools, bulk: true do |t|
      t.string :source_kind, null: false, default: 'custom'
      t.string :provider_key
      t.string :category_key
      t.string :template_key
      t.string :template_version
      t.string :definition_digest
      t.jsonb :definition, null: false, default: {}
      t.jsonb :configuration, null: false, default: {}
      t.jsonb :input_schema, null: false, default: {}
      t.jsonb :output_schema, null: false, default: {}
      t.string :risk_class
      t.bigint :integration_hook_id
    end

    add_foreign_key :captain_custom_tools, :integrations_hooks, column: :integration_hook_id, on_delete: :nullify
  end

  def add_refresh_token_to_integration_hooks
    add_column :integrations_hooks, :refresh_token, :string
  end

  def create_tool_catalog_installations
    create_table :captain_tool_catalog_installations do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.references :initiated_by, null: false, foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :integration_hook, foreign_key: { to_table: :integrations_hooks, on_delete: :nullify }
      t.string :provider_key, null: false
      t.jsonb :selected_templates, null: false, default: []
      t.string :status, null: false, default: 'pending'
      t.string :oauth_nonce_digest
      t.datetime :expires_at, null: false
      t.bigint :resulting_tool_ids, null: false, default: [], array: true
      t.string :error_code
      t.datetime :completed_at

      t.timestamps
    end
  end

  def add_tool_catalog_installation_indexes
    add_index :captain_tool_catalog_installations, [:account_id, :status], name: 'idx_catalog_installations_account_status'
    add_index :captain_tool_catalog_installations, :expires_at, name: 'idx_catalog_installations_expires_at'
    add_index :captain_tool_catalog_installations, :oauth_nonce_digest,
              unique: true,
              where: 'oauth_nonce_digest IS NOT NULL',
              name: 'idx_catalog_installations_oauth_nonce'
  end

  def add_catalog_constraints
    add_check_constraint :captain_custom_tools,
                         "source_kind IN ('custom', 'generated', 'catalog')",
                         name: 'captain_custom_tools_source_kind_check'
    add_check_constraint :captain_custom_tools,
                         "risk_class IS NULL OR risk_class IN ('read', 'low_impact_write', 'approval_required')",
                         name: 'captain_custom_tools_risk_class_check'
    add_check_constraint :captain_custom_tools,
                         "source_kind <> 'catalog' OR (auth_type = 'none' AND auth_config = '{}'::jsonb)",
                         name: 'captain_custom_tools_catalog_auth_check'
    add_check_constraint :captain_tool_catalog_installations,
                         "status IN ('pending', 'awaiting_connection', 'validating', 'installing', 'completed', 'failed', 'expired')",
                         name: 'captain_catalog_installations_status_check'
  end
end
