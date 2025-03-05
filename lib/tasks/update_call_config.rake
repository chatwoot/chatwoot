namespace :custom_attributes do # rubocop:disable Metrics/BlockLength
  desc 'Update call_config structure in custom_attributes for all accounts'
  task update_call_config_structure: :environment do
    Account.find_each do |account|
      # Skip if no call_config exists
      next if account.custom_attributes['call_config'].blank?

      old_config = account.custom_attributes['call_config']

      # Skip if already in new format
      next if old_config['externalProvider'].present?

      # Create new structure
      new_config = {
        'externalProvider' => 'exotel',
        'enabled' => old_config['enabled'] || true,
        'externalProviderConfig' => {
          'sid' => old_config['sid'],
          'token' => old_config['token'],
          'apiKey' => old_config['apiKey'],
          'callerId' => old_config['callerId'],
          'subDomain' => old_config['subDomain']
        }
      }

      # Update the custom_attributes
      account.custom_attributes['call_config'] = new_config

      if account.save
        puts "✅ Successfully updated call_config for Account ##{account.id}"
      else
        puts "❌ Failed to update Account ##{account.id}: #{account.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      puts "❌ Error processing Account ##{account.id}: #{e.message}"
    end

    puts '🎉 Completed updating call_config structure for all accounts'
  end

  # Add a rollback task in case we need to revert the changes
  desc 'Rollback call_config structure changes'
  task rollback_call_config_structure: :environment do
    Account.find_each do |account|
      next if account.custom_attributes['call_config'].blank?

      new_config = account.custom_attributes['call_config']
      next if new_config['externalProviderConfig'].blank?

      # Convert back to old structure
      old_config = {
        'sid' => new_config['externalProviderConfig']['sid'],
        'token' => new_config['externalProviderConfig']['token'],
        'apiKey' => new_config['externalProviderConfig']['apiKey'],
        'callerId' => new_config['externalProviderConfig']['callerId'],
        'subDomain' => new_config['externalProviderConfig']['subDomain'],
        'enabled' => new_config['enabled']
      }

      account.custom_attributes['call_config'] = old_config

      if account.save
        puts "✅ Successfully rolled back call_config for Account ##{account.id}"
      else
        puts "❌ Failed to rollback Account ##{account.id}: #{account.errors.full_messages.join(', ')}"
      end
    rescue StandardError => e
      puts "❌ Error rolling back Account ##{account.id}: #{e.message}"
    end

    puts '🎉 Completed rolling back call_config structure for all accounts'
  end
end
