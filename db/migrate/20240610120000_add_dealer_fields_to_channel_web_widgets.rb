class AddDealerFieldsToChannelWebWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :dealer_name, :string
    add_column :channel_web_widgets, :dealer_tagline, :string
  end
end 