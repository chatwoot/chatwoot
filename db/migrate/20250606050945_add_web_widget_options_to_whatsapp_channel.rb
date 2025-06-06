class AddWebWidgetOptionsToWhatsappChannel < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_whatsapp, :web_widget_options, :jsonb

    Channel::Whatsapp.reset_column_information
    Channel::Whatsapp.find_each do |record|
      position = "right"
      record.update_column(:web_widget_options,  {
        position: position
      })
    end

  end
end
