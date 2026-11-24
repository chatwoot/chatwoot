# The old Copilot had its own model setting, separate from Copilot workflows, which is now the only Copilot. Its saved
# choice is removed, because the Captain model check rejects a saved feature that no longer exists the next time the
# account's models change.
class Migration::RemoveOldCopilotModelSettingsJob < ApplicationJob
  queue_as :async_database_migration

  OLD_FEATURE = 'copilot'.freeze

  def perform
    Account.find_each do |account|
      models = account.captain_models || {}
      features = account.captain_features || {}
      next unless models.key?(OLD_FEATURE) || features.key?(OLD_FEATURE)

      account.update!(captain_models: models.except(OLD_FEATURE), captain_features: features.except(OLD_FEATURE))
      Rails.logger.info("[old-copilot-model-settings] removed for account_id=#{account.id}")
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[old-copilot-model-settings] account_id=#{account.id} #{e.record.errors.full_messages.to_sentence}")
    end
  end
end
