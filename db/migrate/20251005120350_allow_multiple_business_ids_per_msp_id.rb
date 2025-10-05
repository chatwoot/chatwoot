class AllowMultipleBusinessIdsPerMspId < ActiveRecord::Migration[7.1]
  def change
    # Remove the unique constraint on msp_id to allow multiple business_ids per MSP
    remove_index :channel_apple_messages_for_business, :msp_id, if_exists: true

    # Add a composite unique index on msp_id and business_id
    add_index :channel_apple_messages_for_business, [:msp_id, :business_id],
              unique: true,
              name: 'index_channel_amb_on_msp_id_and_business_id'
  end
end
