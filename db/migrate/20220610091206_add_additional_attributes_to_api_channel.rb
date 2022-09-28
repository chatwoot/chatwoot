class AddAdditionalAttributesToApiChannel < ActiveRecord::Migration[6.1]
  def change
    add_column :channel_api, :additional_attributes, :jsonb, default: {}
  end
end
