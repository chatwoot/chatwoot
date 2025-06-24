class AddAdditionalAttributesToChannelWebWidgets < ActiveRecord::Migration[7.0]
  def change
    add_column :channel_web_widgets, :additional_attributes, :jsonb, default: {}
  end
end
