class RepurposeInsertArticleInReplyForBrandedEmailTemplates < ActiveRecord::Migration[7.1]
  def up
    Account.feature_branded_email_templates.find_each(batch_size: 100) do |account|
      account.disable_features(:branded_email_templates)
      account.save!(validate: false)
    end

    remove_stale_default_feature
  end

  private

  def remove_stale_default_feature
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |feature| feature['name'] == 'insert_article_in_reply' }
    config.save!
    GlobalConfig.clear_cache
  end
end
