class CreateChannelEvolution < ActiveRecord::Migration[7.0]
  def change
    create_table 'channel_evolution' do |t|
      t.integer 'account_id', null: false
      t.string 'webhook_url'
      t.datetime 'created_at', null: false
      t.datetime 'updated_at', null: false
      t.string 'identifier'
      t.string 'hmac_token'
      t.string 'qr_code'
      t.string 'instance_id'
      t.boolean 'hmac_mandatory', default: false
      t.jsonb 'additional_attributes', default: {}
      t.index ['hmac_token'], name: 'index_channel_evolution_on_hmac_token', unique: true
      t.index ['identifier'], name: 'index_channel_evolution_on_identifier', unique: true
    end
  end
end
