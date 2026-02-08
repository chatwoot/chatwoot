class TestData::CleanupService
  DATA_FILE = 'tmp/test_data_account_ids.txt'.freeze

  class << self
    def call
      Rails.logger.info 'Cleaning up any existing test data...'

      return log_no_file_found unless file_exists?

      account_ids = parse_account_ids_from_file

      if account_ids.any?
        delete_accounts(account_ids)
      else
        log_no_accounts_found
      end

      delete_data_file
      Rails.logger.info '==> Cleanup complete!'
    end

    private

    def file_exists?
      File.exist?(DATA_FILE)
    end

    def log_no_file_found
      Rails.logger.info 'No test data file found, skipping cleanup'
    end

    def parse_account_ids_from_file
      File.read(DATA_FILE).split(',').map(&:strip).reject(&:empty?).map(&:to_i)
    end

    def delete_accounts(account_ids)
      Rails.logger.info "Found #{account_ids.size} test accounts to clean up: #{account_ids.join(', ')}"
      start_time = Time.zone.now
      Account.where(id: account_ids).destroy_all
      Rails.logger.info "Deleted #{account_ids.size} accounts in #{Time.zone.now - start_time}s"
    end

    def log_no_accounts_found
      Rails.logger.info 'No test account IDs found in the data file'
    end

    def delete_data_file
      File.delete(DATA_FILE)
    end
  end
end
