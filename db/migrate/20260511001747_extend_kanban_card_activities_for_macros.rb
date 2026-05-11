class ExtendKanbanCardActivitiesForMacros < ActiveRecord::Migration[7.1]
  def up
    add_column :kanban_card_activities, :source, :integer, default: 0, null: false
    add_column :kanban_card_activities, :event_type, :integer, default: 0, null: false
    add_column :kanban_card_activities, :metadata, :jsonb, default: {}, null: false

    change_column_null :kanban_card_activities, :to_column_id, true
    change_column_null :kanban_card_activities, :user_id, true

    add_index :kanban_card_activities, :event_type, name: 'index_kanban_card_activities_on_event_type'
  end

  def down
    remove_index :kanban_card_activities, name: 'index_kanban_card_activities_on_event_type'

    KanbanCardActivity.where(to_column_id: nil).delete_all
    KanbanCardActivity.where(user_id: nil).delete_all

    change_column_null :kanban_card_activities, :to_column_id, false
    change_column_null :kanban_card_activities, :user_id, false

    remove_column :kanban_card_activities, :metadata
    remove_column :kanban_card_activities, :event_type
    remove_column :kanban_card_activities, :source
  end
end
