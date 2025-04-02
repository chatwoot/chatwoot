# Move constants outside the namespace block
NUM_ACCOUNTS = 20
MIN_MESSAGES = 1_000_000  # 1M
MAX_MESSAGES = 10_000_000 # 10M
BATCH_SIZE = 5_000 # Increased batch size
START_ID = nil # Will be set dynamically
MAX_CONVERSATIONS_PER_CONTACT = 20
INBOXES_PER_ACCOUNT = 5 # Number of API inboxes per account
STATUSES = %w[open resolved pending].freeze
MESSAGE_TYPES = %w[incoming outgoing].freeze
MIN_MESSAGES_PER_CONVO = 5
MAX_MESSAGES_PER_CONVO = 50

# Define collection constants
COMPANY_TYPES = %w[Retail Healthcare Finance Education Manufacturing].freeze
DOMAIN_EXTENSIONS = %w[com io tech ai].freeze
COUNTRY_CODES = %w[1 44 91 61 81 86 49 33 34 39].freeze # US, UK, India, Australia, Japan, China, Germany, France, Spain, Italy

module DatabaseOptimizer
  module_function

  def setup_database_optimizations
    puts '==> Setting up database optimizations'
    ActiveRecord::Base.logger = nil
    ActiveRecord::Base.connection.execute('SET statement_timeout = 0')
    ActiveRecord::Base.connection.execute('SET synchronous_commit = off')
    ActiveRecord::Base.connection.execute('ALTER TABLE conversations DISABLE TRIGGER ALL')
    ActiveRecord::Base.connection.execute('ALTER TABLE messages DISABLE TRIGGER ALL')
  end

  def restore_database_settings
    ActiveRecord::Base.connection.execute('SET synchronous_commit = on')
    ActiveRecord::Base.connection.execute('ALTER TABLE conversations ENABLE TRIGGER ALL')
    ActiveRecord::Base.connection.execute('ALTER TABLE messages ENABLE TRIGGER ALL')
  end
end

module ContactGenerator
  module_function

  def generate_contacts_data(account, batch_size)
    Array.new(batch_size) do
      created_at = Faker::Time.between(from: 1.year.ago, to: Time.current)
      {
        account_id: account.id,
        name: Faker::Name.name,
        email: "#{SecureRandom.uuid}@example.com",
        phone_number: generate_e164_phone_number,
        additional_attributes: generate_additional_attributes,
        created_at: created_at,
        updated_at: created_at
      }
    end
  end

  def generate_e164_phone_number
    return nil unless rand < 0.7

    country_code = COUNTRY_CODES.sample
    # Generate a number between 7-10 digits (excluding country code)
    subscriber_number = rand(1_000_000..9_999_999_999).to_s
    # Ensure total length is appropriate for E.164 (max 15 digits)
    subscriber_number = subscriber_number[0...(15 - country_code.length)]

    "+#{country_code}#{subscriber_number}"
  end

  def generate_additional_attributes
    return unless rand < 0.3

    {
      company: Faker::Company.name,
      city: Faker::Address.city,
      country: Faker::Address.country_code
    }
  end

  def generate_contact_inboxes_data(contacts, inboxes)
    contacts.flat_map do |contact|
      inboxes.map do |inbox|
        {
          inbox_id: inbox.id,
          contact_id: contact.id,
          source_id: SecureRandom.uuid,
          created_at: contact.created_at,
          updated_at: contact.created_at
        }
      end
    end
  end
end

module ConversationGenerator
  module_function

  def generate_conversations_data(account, contact_inboxes, display_id_data)
    conversations = []

    contact_inboxes.each do |contact_inbox|
      num_conversations = rand(1..MAX_CONVERSATIONS_PER_CONTACT)

      num_conversations.times do
        created_at = Faker::Time.between(from: contact_inbox.created_at, to: Time.current)
        conversations << {
          account_id: account.id,
          inbox_id: contact_inbox.inbox_id,
          contact_id: contact_inbox.contact_id,
          contact_inbox_id: contact_inbox.id,
          status: STATUSES.sample,
          created_at: created_at,
          updated_at: created_at,
          display_id: display_id_data[:next_id]
        }
        display_id_data[:next_id] += 1
      end
    end

    conversations
  end
end

module MessageGenerator
  module_function

  def generate_and_insert_messages(account, conversations)
    total_messages = 0

    conversations.each_slice(1000) do |batch|
      messages_data = batch.flat_map do |conversation|
        num_messages = rand(MIN_MESSAGES_PER_CONVO..MAX_MESSAGES_PER_CONVO)
        generate_messages_for_conversation(account, conversation, num_messages)
      end

      # Use bulk insert instead of individual inserts
      Message.insert_all!(messages_data) if messages_data.any?

      total_messages += messages_data.size
    end

    total_messages
  end

  def generate_messages_for_conversation(account, conversation, count)
    message_type = MESSAGE_TYPES.sample
    time_range = message_time_range(conversation)

    count.times.map do |_i|
      message_type = alternate_message_type(message_type)
      generate_message(account, conversation, message_type, time_range)
    end
  end

  def generate_message(account, conversation, message_type, time_range)
    created_at = Faker::Time.between(from: time_range.first, to: time_range.last)
    {
      account_id: account.id,
      inbox_id: conversation.inbox_id,
      conversation_id: conversation.id,
      message_type: message_type,
      content: Faker::Lorem.paragraph(sentence_count: 2),
      created_at: created_at,
      updated_at: created_at,
      private: false,
      status: 'sent',
      content_type: 'text',
      source_id: SecureRandom.uuid
    }
  end

  def message_time_range(conversation)
    start_time = conversation.created_at || 1.year.ago
    end_time = Time.current
    [start_time, end_time]
  end

  def alternate_message_type(current_type)
    current_type == 'incoming' ? 'outgoing' : 'incoming'
  end
end

module DataTasks
  module_function

  def bulk_insert_contacts(contacts_data)
    Contact.insert_all!(contacts_data) if contacts_data.any?
  end

  def bulk_insert_contact_inboxes(contact_inboxes_data)
    ContactInbox.insert_all!(contact_inboxes_data) if contact_inboxes_data.any?
  end
end

module TestDataGenerator
  module_function

  def generate_account_data(account)
    target_message_count = rand(MIN_MESSAGES..MAX_MESSAGES)
    avg_msgs_per_conversation = rand(15..50)
    total_conversations_needed = (target_message_count / avg_msgs_per_conversation.to_f).ceil
    total_contacts_needed = (total_conversations_needed / MAX_CONVERSATIONS_PER_CONTACT.to_f).ceil

    puts "==> Creating Account ##{account.id} with target of #{target_message_count / 1_000_000}M messages"
    puts "    Planning for #{total_contacts_needed} contacts and #{total_conversations_needed} conversations"

    [target_message_count, total_contacts_needed]
  end

  def process_contacts_batch(account, inboxes, batch_size, display_id_data)
    contacts_data = ContactGenerator.generate_contacts_data(account, batch_size)
    DataTasks.bulk_insert_contacts(contacts_data)

    new_contacts = Contact.where(account_id: account.id)
                          .order(created_at: :desc)
                          .limit(batch_size)

    contact_inboxes_data = ContactGenerator.generate_contact_inboxes_data(new_contacts, inboxes)
    DataTasks.bulk_insert_contact_inboxes(contact_inboxes_data)

    contact_inboxes = ContactInbox.where(contact_id: new_contacts.pluck(:id))

    conversations_data = ConversationGenerator.generate_conversations_data(account, contact_inboxes, display_id_data)

    # Use bulk insert for conversations and fetch them back with timestamps
    Conversation.insert_all!(conversations_data)
    created_conversations = Conversation.where(
      account_id: account.id,
      display_id: conversations_data.pluck(:display_id)
    ).order(:created_at)

    # Generate and insert messages for the created conversations
    MessageGenerator.generate_and_insert_messages(account, created_conversations)
  end
end

# Move task logic to a separate service class
class TestDataGenerationService
  class << self
    def generate_test_data
      cleanup_existing_data
      set_start_id

      puts "Starting to generate distributed test data across #{NUM_ACCOUNTS} accounts..."
      puts "Each account will have #{INBOXES_PER_ACCOUNT} API inboxes"
      puts "Each account will have between #{MIN_MESSAGES / 1_000_000}M and #{MAX_MESSAGES / 1_000_000}M messages"

      (0...NUM_ACCOUNTS).each do |account_index|
        process_account(account_index)
      end

      puts "ALL DONE! Created #{NUM_ACCOUNTS} accounts with distributed test data"
    end

    private

    def cleanup_existing_data
      puts 'Cleaning up any existing test data...'
      return unless File.exist?('tmp/test_data_account_ids.txt')

      account_ids = File.read('tmp/test_data_account_ids.txt').split(',')
      Account.where(id: account_ids).destroy_all
      File.delete('tmp/test_data_account_ids.txt')
    end

    def set_start_id
      # Find the maximum account ID and start after that to avoid conflicts
      max_id = Account.maximum(:id) || 0
      Object.const_set(:START_ID, max_id + 1)
      puts "Setting START_ID to #{START_ID}"
    end

    def create_account(id)
      company_name = "#{Faker::Company.name} #{COMPANY_TYPES.sample}"
      domain = "#{company_name.parameterize}.#{DOMAIN_EXTENSIONS.sample}"

      account = Account.create!(
        id: id,
        name: company_name,
        domain: domain,
        created_at: Faker::Time.between(from: 2.years.ago, to: 6.months.ago)
      )

      # Store the account ID for future cleanup
      File.open('tmp/test_data_account_ids.txt', 'a') do |f|
        f.puts(account.id)
      end

      account
    end

    def create_inboxes(account)
      Array.new(INBOXES_PER_ACCOUNT) do
        channel = Channel::Api.create!(account: account)
        Inbox.create!(
          account_id: account.id,
          name: "API Inbox #{SecureRandom.hex(4)}",
          channel: channel
        )
      end
    end

    def process_account(account_index)
      account = create_account(START_ID + account_index)
      inboxes = create_inboxes(account)

      target_message_count, total_contacts_needed = TestDataGenerator.generate_account_data(account)
      process_account_data(account, inboxes, total_contacts_needed, target_message_count)
    end

    def process_account_data(account, inboxes, total_contacts_needed, target_message_count)
      # Get the maximum display_id for this account to ensure uniqueness
      max_display_id = Conversation.where(account_id: account.id).maximum(:display_id) || 0
      next_display_id = max_display_id + 1

      contact_count = 0
      message_count = 0

      while contact_count < total_contacts_needed
        batch_size = [BATCH_SIZE, total_contacts_needed - contact_count].min

        # Pass next_display_id by reference so it can be updated
        display_id_data = { next_id: next_display_id }
        batch_message_count = TestDataGenerator.process_contacts_batch(account, inboxes, batch_size, display_id_data)

        # Update next_display_id for the next batch
        next_display_id = display_id_data[:next_id]

        contact_count += batch_size
        message_count += batch_message_count
        puts "    Created #{contact_count}/#{total_contacts_needed} contacts, #{message_count}/#{target_message_count} messages"
      end

      puts "==> Completed Account ##{account.id} with #{message_count} messages"
    end
  end
end

# Keep namespace minimal
namespace :data do
  desc 'Generate distributed test data across 20 accounts with 1M-10M messages each and realistic patterns'
  task generate_distributed_data: :environment do
    if Rails.env.production?
      puts 'Generating large amounts of data in production can have serious performance implications.'
      puts 'Exiting to avoid impacting a live environment.'
      exit
    end

    begin
      DatabaseOptimizer.setup_database_optimizations
      TestDataGenerationService.generate_test_data
    ensure
      DatabaseOptimizer.restore_database_settings
    end
  end

  desc 'Clean up existing test data'
  task cleanup_test_data: :environment do
    TestDataGenerationService.send(:cleanup_existing_data)
  end
end
