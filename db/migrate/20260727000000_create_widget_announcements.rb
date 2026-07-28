class CreateWidgetAnnouncements < ActiveRecord::Migration[7.1]
  def change
    create_table :widget_announcements do |t|
      t.references :account, null: false
      t.references :inbox, null: false
      t.string :title, null: false
      t.text :message
      t.integer :level, default: 0, null: false
      t.string :action_url
      t.datetime :starts_at
      t.datetime :ends_at
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :widget_announcements, [:inbox_id, :enabled]
  end
end
