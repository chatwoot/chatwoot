# ConfigLoader runs after migrations, so save the stored default before backfilling accounts.
# Each batch commits independently to avoid holding locks across the entire account base.
class EnableDataImportForAllAccounts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    enable_default
    remove_data_import_from_shopify_plans
    remove_data_import_from_billing_metadata

    Account.not_feature_data_import.in_batches(of: 1000) do |batch|
      # FlagShihTzu preserves unrelated flags; bulk updates avoid per-account validations and callbacks.
      batch.update_all(Account.set_flag_sql(:feature_data_import, true)) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    # Preserve account feature settings when rolling back the application.
  end

  private

  def enable_default
    entry = Featurable::FEATURE_LIST.find { |feature| feature['name'] == 'data_import' }
    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    others = Array(config.value).reject { |feature| feature['name'] == 'data_import' }
    config.update!(value: others + [entry.merge('enabled' => true)])
  end

  def remove_data_import_from_shopify_plans
    config = InstallationConfig.find_by(name: 'CHATWOOT_SHOPIFY_PLANS')
    return unless config

    config.with_lock do
      plans = config.value.map do |plan|
        plan.merge('features' => plan.fetch('features').without('data_import'))
      end
      config.update!(value: plans)
    end
  end

  def remove_data_import_from_billing_metadata
    %w[shopify_managed_features manually_managed_features].each do |key|
      condition = Account.arel_table[:internal_attributes].contains(key => ['data_import'])
      Account.where(condition).find_each(batch_size: 1000) do |account|
        account.with_lock do
          features = account.internal_attributes[key]
          next unless features&.include?('data_import')

          attributes = account.internal_attributes.merge(key => features.without('data_import'))
          account.update!(internal_attributes: attributes)
        end
      end
    end
  end
end
