class BackfillCaptainCustomToolAssistants < ActiveRecord::Migration[7.2]
  def up
    duplicate_tools_for_other_assistants

    # Accounts without assistants retain their original tools for manual recovery.
    execute <<~SQL.squish
      UPDATE captain_custom_tools tools
      SET assistant_id = (
        SELECT MIN(id) FROM captain_assistants WHERE account_id = tools.account_id
      )
      WHERE tools.assistant_id IS NULL
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, 'Assistant tools may have been edited independently after the backfill'
  end

  private

  def duplicate_tools_for_other_assistants
    # Keep the original tool IDs for the first assistant and preserve slugs for scenario references.
    execute <<~SQL.squish
      INSERT INTO captain_custom_tools (
        account_id, assistant_id, slug, title, description, http_method, endpoint_url,
        request_template, response_template, auth_type, auth_config, param_schema, enabled,
        created_at, updated_at
      )
      SELECT tools.account_id, assistants.id, tools.slug, tools.title, tools.description,
        tools.http_method, tools.endpoint_url, tools.request_template, tools.response_template,
        tools.auth_type, tools.auth_config, tools.param_schema, tools.enabled,
        tools.created_at, tools.updated_at
      FROM captain_custom_tools tools
      INNER JOIN captain_assistants assistants ON assistants.account_id = tools.account_id
      WHERE tools.assistant_id IS NULL
        AND assistants.id != (
          SELECT MIN(id) FROM captain_assistants WHERE account_id = tools.account_id
        )
    SQL
  end
end
