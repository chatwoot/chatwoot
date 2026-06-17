class FixDoubleEncodedJsonInMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    # Fix content_attributes (json column)
    # The value was double-encoded by coder: JSON, so we extract the inner string using #>> '{}'
    # and then cast it back to json natively in PostgreSQL.
    execute <<-SQL.squish
      UPDATE messages 
      SET content_attributes = (content_attributes#>>'{}')::json 
      WHERE json_typeof(content_attributes) = 'string';
    SQL

    # Fix external_source_ids (jsonb column)
    execute <<-SQL.squish
      UPDATE messages 
      SET external_source_ids = (external_source_ids#>>'{}')::jsonb 
      WHERE jsonb_typeof(external_source_ids) = 'string';
    SQL
  end

  def down
    # This migration is not safely reversible because we cannot distinguish between 
    # data that was originally correctly encoded and data that was fixed by the `up` step.
    # Re-encoding everything into double-encoded strings would just re-introduce the bug.
    raise ActiveRecord::IrreversibleMigration
  end
end
