class TestData::Orchestrator
  class << self
    def call
      cleanup_existing_data
      set_start_id

      Rails.logger.debug { "Starting to generate distributed test data across #{Constants::NUM_ACCOUNTS} accounts..." }
      Rails.logger.debug do
        "Each account will have between #{Constants::MIN_MESSAGES / 1_000_000}M and #{Constants::MAX_MESSAGES / 1_000_000}M messages"
      end

      Constants::NUM_ACCOUNTS.times do |account_index|
        process_account(account_index)
      end

      Rails.logger.debug { "ALL DONE! Created #{Constants::NUM_ACCOUNTS} accounts with distributed test data" }
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
      CleanupService.call
    end

    # 2. Find the max Account ID to avoid conflicts
    def set_start_id
      max_id = Account.maximum(:id) || 0
      @start_id = max_id + 1
      Rails.logger.debug { "Setting start ID to #{@start_id}" }
    end

    # 3. Create an account, its inboxes, and some data
    def process_account(account_index)
      account_id = @start_id + account_index
      account = AccountCreator.create!(account_id)

      inboxes = InboxCreator.create_for(account)
      target_messages = rand(Constants::MIN_MESSAGES..Constants::MAX_MESSAGES)
      avg_per_convo = rand(15..50)
      total_convos = (target_messages / avg_per_convo.to_f).ceil
      total_contacts = (total_convos / Constants::MAX_CONVERSATIONS_PER_CONTACT.to_f).ceil

      log_account_details(account, target_messages, total_contacts, total_convos)

      display_id_tracker = DisplayIdTracker.new(account: account)

      params = DataGenerationParams.new(
        account: account,
        inboxes: inboxes,
        total_contacts_needed: total_contacts,
        target_message_count: target_messages,
        display_id_tracker: display_id_tracker
      )

      generate_data_for_account(params)
    end

    def generate_data_for_account(params)
      contact_count = 0
      message_count = 0

      while contact_count < params.total_contacts_needed
        batch_size = [Constants::BATCH_SIZE, params.total_contacts_needed - contact_count].min
        batch_service = ContactBatchService.new(
          account: params.account,
          inboxes: params.inboxes,
          batch_size: batch_size,
          display_id_tracker: params.display_id_tracker
        )
        batch_created_messages = batch_service.generate!

        contact_count += batch_size
        message_count += batch_created_messages

        Rails.logger.debug do
          "    Created #{contact_count}/#{params.total_contacts_needed} contacts, " \
            "#{message_count}/#{params.target_message_count} messages"
        end
      end

      Rails.logger.debug { "==> Completed Account ##{params.account.id} with #{message_count} messages" }
    end

    def log_account_details(account, target_messages, total_contacts, total_convos)
      Rails.logger.debug { "==> Creating Account ##{account.id} with target of #{target_messages / 1_000_000}M messages" }
      Rails.logger.debug { "    Planning for #{total_contacts} contacts and #{total_convos} conversations" }
    end
  end
end
