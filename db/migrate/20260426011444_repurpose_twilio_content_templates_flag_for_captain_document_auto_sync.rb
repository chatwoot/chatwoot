class RepurposeTwilioContentTemplatesFlagForCaptainDocumentAutoSync < ActiveRecord::Migration[7.1]
  def up
    # The twilio_content_templates flag (deprecated) has been renamed to captain_document_auto_sync.
    # Disable it on any accounts that had twilio_content_templates enabled so the repurposed
    # flag starts in its intended default-off state.
    Account.feature_captain_document_auto_sync.find_each(batch_size: 100) do |account|
      account.disable_features(:captain_document_auto_sync)
      account.save!(validate: false)
    end

    # Remove the stale twilio_content_templates entry from ACCOUNT_LEVEL_FEATURE_DEFAULTS.
    # ConfigLoader only adds new flags; it never removes renamed ones.
    # Leaving it would cause NoMethodError in enable_default_features when
    # creating new accounts (feature_twilio_content_templates= no longer exists).
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |f| f['name'] == 'twilio_content_templates' }
    config.save!
    GlobalConfig.clear_cache
  end
end
