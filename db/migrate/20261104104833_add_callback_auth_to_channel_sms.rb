class AddCallbackAuthToChannelSms < ActiveRecord::Migration[7.2]
  def up
    add_column :channel_sms, :secret, :string
    add_column :channel_sms, :callback_auth_enforced, :boolean, default: false, null: false
    change_column_default :channel_sms, :callback_auth_enforced, from: false, to: true

    Channel::Sms.reset_column_information
    Channel::Sms.where(secret: nil).find_each do |channel|
      channel.update_column(:secret, Channel::Sms.generate_unique_secure_token) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    remove_column :channel_sms, :callback_auth_enforced
    remove_column :channel_sms, :secret
  end
end
