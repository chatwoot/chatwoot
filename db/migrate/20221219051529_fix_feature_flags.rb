class FixFeatureFlags < ActiveRecord::Migration[6.1]
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/BlockLength
  def change
    installation_config = InstallationConfig.find_by(name: 'DEPLOYMENT_ENV')
    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        if installation_config == 'cloud'
          account.enable_features(
            'reports',
            'crm',
            'auto_resolve_conversations'
          )
        else
          account.enable_features(
            'inbound_emails',
            'channel_website',
            'channel_email',
            'channel_facebook',
            'channel_twitter',
            'ip_lookup',
            'email_continuity_on_api_channel',
            'campaigns',
            'help_center',
            'macros',
            'agent_management',
            'team_management',
            'inbox_management',
            'labels',
            'custom_attributes',
            'automations',
            'canned_responses',
            'integrations',
            'voice_recorder',
            'reports',
            'crm',
            'auto_resolve_conversations'
          )
        end
        account.save!
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/BlockLength
end
