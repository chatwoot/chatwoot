class RenameLeaveTableToLeaveRecords < ActiveRecord::Migration[7.1]
  def change
    rename_table :leaves, :leave_records
  end
end
