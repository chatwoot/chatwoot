class TestData::ContactsCleanupService
  DATA_FILE = 'tmp/test_data_account_ids.txt'.freeze

  class << self
    def call
      Rails.logger.info { 'Cleaning up existing contacts test data...' }

      # Read account IDs from file
      unless File.exist?(DATA_FILE)
        Rails.logger.warn { 'No test data file found to clean up' }
        return
      end

      account_ids = File.read(DATA_FILE).split(',').map(&:to_i).compact
      if account_ids.empty?
        Rails.logger.warn { 'No test data found to clean up' }
        return
      end

      test_accounts = Account.where(id: account_ids)
      Rails.logger.info { "Found #{test_accounts.count} test accounts to clean up" }

      # Delete related data
      Contact.where(account_id: account_ids).delete_all
      Company.where(account_id: account_ids).delete_all
      test_accounts.delete_all

      # Clear the file
      File.delete(DATA_FILE)

      Rails.logger.info { 'Cleanup complete' }
    end
  end
end
