class AddChannelWebWidgetToPortals < ActiveRecord::Migration[7.0]
  def change
    add_reference :portals, :channel_web_widget, foreign_key: { to_table: :channel_web_widgets }
  end
end
