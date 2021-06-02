class AddHmacToApiChannel < ActiveRecord::Migration[6.0]
  def change
    add_column :channel_api, :identifier, :string
    add_index :channel_api, :identifier, unique: true
    add_column :channel_api, :hmac_token, :string
    add_index :channel_api, :hmac_token, unique: true
    add_column :channel_api, :hmac_mandatory, :boolean, default: false
    add_column :channel_web_widgets, :hmac_mandatory, :boolean, default: false
    set_up_existing_api_channels
  end

  def set_up_existing_api_channels
    ::Channel::Api.find_in_batches do |api_channels_batch|
      Rails.logger.info "migrated till #{api_channels_batch.first.id}\n"
      api_channels_batch.map(&:regenerate_hmac_token)
      api_channels_batch.map(&:regenerate_identifier)
    end
  end
end
