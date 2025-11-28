class AddPriorityGroupIdToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_reference :inboxes, :priority_group, null: true, foreign_key: true
  end
end
