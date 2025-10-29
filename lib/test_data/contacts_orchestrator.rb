class TestData::ContactsOrchestrator
  class << self
    def call
      Rails.logger.info { '========== STARTING CONTACTS-ONLY DATA GENERATION ==========' }

      cleanup_existing_data
      set_start_id

      num_accounts = configured_num_accounts
      contacts_per_account = configured_contacts_per_account

      Rails.logger.info { "Generating #{contacts_per_account} contacts across #{num_accounts} accounts..." }
      Rails.logger.info { "Total contacts to generate: #{num_accounts * contacts_per_account}" }

      num_accounts.times do |account_index|
        Rails.logger.info { "Processing account #{account_index + 1} of #{num_accounts}" }
        process_account(account_index, contacts_per_account)
      end

      Rails.logger.info { "========== DONE! Created #{num_accounts} accounts with #{num_accounts * contacts_per_account} contacts ==========" }
    end

    private

    def cleanup_existing_data
      Rails.logger.info { 'Cleaning up existing contacts test data...' }
      TestData::ContactsCleanupService.call
      Rails.logger.info { 'Cleanup complete' }
    end

    def set_start_id
      max_id = Account.maximum(:id) || 0
      @start_id = max_id + 1
      Rails.logger.info { "Setting start ID to #{@start_id}" }
    end

    def configured_num_accounts
      ENV.fetch('ACCOUNTS', TestData::Constants::NUM_ACCOUNTS).to_i
    end

    def configured_contacts_per_account
      ENV.fetch('CONTACTS_PER_ACCOUNT', 10_000).to_i
    end

    def process_account(account_index, contacts_per_account)
      account_id = @start_id + account_index
      Rails.logger.info { "Creating account with ID #{account_id}" }
      account = TestData::AccountCreator.create!(account_id)

      Rails.logger.info { "Generating #{contacts_per_account} contacts for account ##{account.id}" }
      generator = TestData::ContactsOnlyGenerator.new(
        account: account,
        total_contacts: contacts_per_account
      )
      generator.generate!

      Rails.logger.info { "==> Completed Account ##{account.id} with #{contacts_per_account} contacts" }
    end
  end
end
