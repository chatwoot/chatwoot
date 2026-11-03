# ConfigLoader runs after migrations, so save the stored default before backfilling accounts.
# Each batch commits independently to avoid holding locks across the entire account base.
class EnableDataImportForAllAccounts < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    enable_default

    column, mapping = Account.flag_mapping.find { |_column, flags| flags.key?(:feature_data_import) }
    flags = Account.arel_table[column]
    bit = mapping.fetch(:feature_data_import)
    Account.not_feature_data_import.in_batches(of: 1000) do |batch|
      # Update only this bit in each batch, preserving concurrent flag changes without running account callbacks.
      batch.update_all(column => (flags | bit)) # rubocop:disable Rails/SkipsModelValidations
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
end
