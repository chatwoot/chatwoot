class CreateRailsExecutionFileManages < ActiveRecord::Migration[7.0]
  def change
    create_table :rails_execution_file_manages do |t|
      t.timestamps
      t.integer :task_id, null: false
      t.string :name, null: false
      t.string :attachment_type, default: 'attachment', null: false
    end
  end
end
