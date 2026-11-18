class AddCallHoursSyncToChannelWhatsapp < ActiveRecord::Migration[8.0]
  def change
    change_table :channel_whatsapp, bulk: true do |t|
      t.string :call_hours_sync_status
      t.text :call_hours_sync_error
      t.datetime :call_hours_synced_at
      t.jsonb :call_hours_last_payload
    end
  end
end
