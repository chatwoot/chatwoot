class ChannelWebWidgetSchemaChange < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :need_more_help_type, :string, default: 'redirect_to_whatsapp'
  end
end
