class AddWidgetConfigToChannelWebWidgets < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_web_widgets, :widget_position, :string, default: 'right'
    add_column :channel_web_widgets, :widget_type, :string, default: 'standard'
    add_column :channel_web_widgets, :launcher_title, :string, default: 'Chat with us'
  end
end
