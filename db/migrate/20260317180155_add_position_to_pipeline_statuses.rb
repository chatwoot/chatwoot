class AddPositionToPipelineStatuses < ActiveRecord::Migration[7.1]
  def change
    add_column :pipeline_statuses, :position, :integer
    add_index :pipeline_statuses, %i[account_id position]

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE pipeline_statuses ps
          SET position = sub.row_num
          FROM (
            SELECT id, ROW_NUMBER() OVER (PARTITION BY account_id ORDER BY created_at ASC) AS row_num
            FROM pipeline_statuses
          ) sub
          WHERE ps.id = sub.id
        SQL
      end
    end
  end
end
