class EnableWhatsappInteractiveFeatures < ActiveRecord::Migration[7.1]
  FEATURE_NAMES = %w[
    whatsapp_interactive_button
    whatsapp_interactive_list
    whatsapp_interactive_carousel
    whatsapp_interactive_cta_url
  ].freeze

  def up
    update_default_configuration

    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each do |account|
        account.enable_features(*FEATURE_NAMES)
        account.save!
      end
    end

    GlobalConfig.clear_cache
  end

  private

  def update_default_configuration
    config = InstallationConfig.find_by!(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

    features = config.value.to_a
    configured_names = features.pluck('name')
    FEATURE_NAMES.each do |name|
      features << { 'name' => name, 'enabled' => true } unless configured_names.include?(name)
    end
    config.update!(value: features)
  end
end
