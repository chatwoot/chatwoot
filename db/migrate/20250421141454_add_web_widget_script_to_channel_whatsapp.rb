class AddWebWidgetScriptToChannelWhatsapp < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_whatsapp, :web_widget_script, :text
  end
end
