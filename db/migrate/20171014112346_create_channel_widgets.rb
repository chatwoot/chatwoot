class CreateChannelWidgets < ActiveRecord::Migration[5.0]
  def change
    create_table :channel_widgets do |t|
      t.string :website_name
      t.string :website_url
      t.integer :account_id

      t.timestamps
    end
  end
end
