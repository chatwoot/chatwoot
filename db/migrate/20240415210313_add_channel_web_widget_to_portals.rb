class AddChannelWebWidgetToPortals < ActiveRecord::Migration[7.0]
  def change
    add_column :portals, :channel_web_widget_id, :bigint
    add_index :portals, :channel_web_widget_id
  end
end
