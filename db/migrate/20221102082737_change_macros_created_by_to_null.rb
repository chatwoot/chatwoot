class ChangeMacrosCreatedByToNull < ActiveRecord::Migration[6.1]
  def change
    change_column_null :macros, :created_by_id, true
    change_column_null :macros, :updated_by_id, true

    remove_index :macros, :created_by_id, if_exists: true
    remove_index :macros, :updated_by_id, if_exists: true
  end
end
