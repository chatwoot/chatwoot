class AddAppleMspPayloadToMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :messages, :apple_msp_payload, :jsonb
  end
end
