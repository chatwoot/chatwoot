class AddPositionToCustomAttributeDefinitions < ActiveRecord::Migration[7.1]
  def up
    add_column :custom_attribute_definitions, :position, :integer

    execute <<~SQL.squish
      UPDATE custom_attribute_definitions cad
      SET position = sub.row_num * 10
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY account_id, attribute_model ORDER BY created_at, id) AS row_num
        FROM custom_attribute_definitions
      ) sub
      WHERE cad.id = sub.id
    SQL
  end

  def down
    remove_column :custom_attribute_definitions, :position
  end
end
