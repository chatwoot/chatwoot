class CreateChannelInternal < ActiveRecord::Migration[7.0]
  def change
    create_table :channel_internal do |t|
      t.integer :account_id, null: false
      t.timestamps
    end
  end
end
