class TestData::Orchestrator
  class << self
    def call
      Rails.logger.info { '========== STARTING TEST DATA GENERATION ==========' }

      cleanup_existing_data
      set_start_id

      Rails.logger.info { "Starting to generate distributed test data across #{TestData::Constants::NUM_ACCOUNTS} accounts..." }
      Rails.logger.info do
        "Each account have between #{TestData::Constants::MIN_MESSAGES / 1_000_000}M and #{TestData::Constants::MAX_MESSAGES / 1_000_000}M messages"
      end

      TestData::Constants::NUM_ACCOUNTS.times do |account_index|
        Rails.logger.info { "Processing account #{account_index + 1} of #{TestData::Constants::NUM_ACCOUNTS}" }
        process_account(account_index)
      end

      Rails.logger.info { "========== ALL DONE! Created #{TestData::Constants::NUM_ACCOUNTS} accounts with distributed test data ==========" }
    end

    private

    # Simple value object to group generation parameters
    class DataGenerationParams
      attr_reader :account, :inboxes, :total_contacts_needed, :target_message_count, :display_id_tracker

      def initialize(account:, inboxes:, total_contacts_needed:, target_message_count:, display_id_tracker:)
        @account = account
        @inboxes = inboxes
        @total_contacts_needed = total_contacts_needed
        @target_message_count = target_message_count
        @display_id_tracker = display_id_tracker
      end
    end

    # 1. Remove existing data for old test accounts
    def cleanup_existing_data
      Rails.logger.info { 'Cleaning up existing test data...' }
      TestData::CleanupService.call
      Rails.logger.info { 'Cleanup complete' }
    end

    # 2. Find the max Account ID to avoid conflicts
    def set_start_id
      max_id = Account.maximum(:id) || 0
      @start_id = max_id + 1
      Rails.logger.info { "Setting start ID to #{@start_id}" }
    end

    # 3. Create an account, its inboxes, and some data
    def process_account(account_index)
      account_id = @start_id + account_index
      Rails.logger.info { "Creating account with ID #{account_id}" }
      account = TestData::AccountCreator.create!(account_id)

      inboxes = TestData::InboxCreator.create_for(account)
      target_messages = rand(TestData::Constants::MIN_MESSAGES..TestData::Constants::MAX_MESSAGES)
      avg_per_convo = rand(15..50)
      total_convos = (target_messages / avg_per_convo.to_f).ceil
      total_contacts = (total_convos / TestData::Constants::MAX_CONVERSATIONS_PER_CONTACT.to_f).ceil

      log_account_details(account, target_messages, total_contacts, total_convos)
      display_id_tracker = TestData::DisplayIdTracker.new(account: account)

      params = DataGenerationParams.new(
        account: account,
        inboxes: inboxes,
        total_contacts_needed: total_contacts,
        target_message_count: target_messages,
        display_id_tracker: display_id_tracker
      )

      Rails.logger.info { "Starting data generation for account ##{account.id}" }
      generate_data_for_account(params)
    end

    def generate_data_for_account(params)
      contact_count = 0
      message_count = 0
      batch_number = 0

      while contact_count < params.total_contacts_needed
        batch_number += 1
        batch_size = [TestData::Constants::BATCH_SIZE, params.total_contacts_needed - contact_count].min
        Rails.logger.info { "Processing batch ##{batch_number} (#{batch_size} contacts) for account ##{params.account.id}" }

        batch_service = TestData::ContactBatchService.new(
          account: params.account,
          inboxes: params.inboxes,
          batch_size: batch_size,
          display_id_tracker: params.display_id_tracker
        )
        batch_created_messages = batch_service.generate!

        contact_count += batch_size
        message_count += batch_created_messages

      end

      Rails.logger.info { "==> Completed Account ##{params.account.id} with #{message_count} messages" }
    end

    def log_account_details(account, target_messages, total_contacts, total_convos)
      Rails.logger.info { "==> Account ##{account.id} plan: target of #{target_messages / 1_000_000.0}M messages" }
      Rails.logger.info { "    Planning for #{total_contacts} contacts and #{total_convos} conversations" }
    end
  end
end
