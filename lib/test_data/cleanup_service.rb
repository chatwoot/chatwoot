module TestData
  class CleanupService
    DATA_FILE = 'tmp/test_data_account_ids.txt'.freeze

    def self.call
      puts 'Cleaning up any existing test data...'
      return unless File.exist?(DATA_FILE)

      account_ids = File.read(DATA_FILE).split(',').map(&:strip).reject(&:empty?).map(&:to_i)
      Account.where(id: account_ids).destroy_all if account_ids.any?
      File.delete(DATA_FILE)
      puts '==> Cleanup complete!'
    end
  end
end
