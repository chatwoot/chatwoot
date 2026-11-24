class EnableAdvancedSearchConversationsForAllAccounts < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    enable_default
    column = 'feature_flags_ext_1'
    bit = Account.flag_mapping.fetch(column).fetch(:feature_advanced_search_conversations)
    flags = Account.arel_table[column]
    Account.where((flags & bit).eq(0)).in_batches(of: 1000) do |batch|
      # Set only this bit atomically; feature enablement must not run per-account callbacks.
      batch.update_all(column => flags | bit) # rubocop:disable Rails/SkipsModelValidations
    end
  end

  def down
    # Preserve account feature settings when rolling back the application.
  end

  private

  def enable_default
    entry = Featurable::FEATURE_LIST.find { |feature| feature['name'] == 'advanced_search_conversations' }
    config = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    others = Array(config.value).reject { |feature| feature['name'] == 'advanced_search_conversations' }
    config.locked = true if config.new_record?
    config.update!(value: others + [entry.merge('enabled' => true)])
  end
end
