class AddSourceMessageToInternalTasks < ActiveRecord::Migration[7.1]
  def change
    add_reference :internal_tasks, :source_message, foreign_key: { to_table: :messages }, null: true, index: true
  end
end
