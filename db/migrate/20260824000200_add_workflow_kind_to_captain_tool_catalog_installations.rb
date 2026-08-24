class AddWorkflowKindToCaptainToolCatalogInstallations < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_tool_catalog_installations, :workflow_kind, :string, null: false, default: 'install'
    add_check_constraint :captain_tool_catalog_installations,
                         "workflow_kind IN ('install', 'update', 'reconnect')",
                         name: 'captain_catalog_installations_workflow_kind_check'
  end
end
