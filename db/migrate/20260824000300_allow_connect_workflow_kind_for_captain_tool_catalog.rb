class AllowConnectWorkflowKindForCaptainToolCatalog < ActiveRecord::Migration[7.1]
  CONSTRAINT_NAME = 'captain_catalog_installations_workflow_kind_check'.freeze

  def up
    remove_check_constraint :captain_tool_catalog_installations, name: CONSTRAINT_NAME
    add_check_constraint :captain_tool_catalog_installations,
                         "workflow_kind IN ('install', 'update', 'reconnect', 'connect')",
                         name: CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :captain_tool_catalog_installations, name: CONSTRAINT_NAME
    add_check_constraint :captain_tool_catalog_installations,
                         "workflow_kind IN ('install', 'update', 'reconnect')",
                         name: CONSTRAINT_NAME
  end
end
