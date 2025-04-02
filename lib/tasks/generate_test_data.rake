# Move constants outside the namespace block
NUM_ACCOUNTS = 20
MIN_MESSAGES = 1_000_000  # 1M
MAX_MESSAGES = 10_000_000 # 10M
BATCH_SIZE = 5_000 # Increased batch size
START_ID = 10
MAX_CONVERSATIONS_PER_CONTACT = 20
INBOXES_PER_ACCOUNT = 5 # Number of API inboxes per account
STATUSES = %w[open resolved pending].freeze
MESSAGE_TYPES = %w[incoming outgoing].freeze
MIN_MESSAGES_PER_CONVO = 5
MAX_MESSAGES_PER_CONVO = 50

# Define collection constants
COMPANY_TYPES = %w[Retail Healthcare Finance Education Manufacturing].freeze
DOMAIN_EXTENSIONS = %w[com io tech ai].freeze

# Move task definitions to separate modules
module DataTasks
  module_function

  def validate_contacts_data(contacts_data)
    contacts_data.each do |data|
      contact = Contact.new(data)
      raise "Invalid contact data: #{contact.errors.full_messages}" unless contact.valid?
    end
  end

  def validate_contact_inboxes_data(contact_inboxes_data)
    contact_inboxes_data.each do |data|
      contact_inbox = ContactInbox.new(data)
      raise "Invalid contact inbox data: #{contact_inbox.errors.full_messages}" unless contact_inbox.valid?
    end
  end

  def validate_conversations_data(conversations_data)
    conversations_data.each do |data|
      conversation = Conversation.new(data)
      raise "Invalid conversation data: #{conversation.errors.full_messages}" unless conversation.valid?
    end
  end

  def bulk_insert_contacts(contacts_data)
    contacts_data.each_slice(1000) do |batch|
      Contact.transaction do
        batch.each { |data| Contact.create!(data) }
      end
    end
  end

  def bulk_insert_contact_inboxes(contact_inboxes_data)
    contact_inboxes_data.each_slice(1000) do |batch|
      ContactInbox.transaction do
        batch.each { |data| ContactInbox.create!(data) }
      end
    end
  end

  def bulk_insert_conversations(conversations_data)
    conversations_data.each_slice(1000) do |batch|
      Conversation.transaction do
        batch.each { |data| Conversation.create!(data) }
      end
    end
  end
end

module TestDataGenerator
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

  def generate_account_data(account)
    target_message_count = rand(MIN_MESSAGES..MAX_MESSAGES)
    avg_msgs_per_conversation = rand(15..50)
    total_conversations_needed = (target_message_count / avg_msgs_per_conversation.to_f).ceil
    total_contacts_needed = (total_conversations_needed / MAX_CONVERSATIONS_PER_CONTACT.to_f).ceil

    puts "==> Creating Account ##{account.id} with target of #{target_message_count / 1_000_000}M messages"
    puts "    Planning for #{total_contacts_needed} contacts and #{total_conversations_needed} conversations"

    [target_message_count, total_contacts_needed]
  end

  def process_contacts_batch(account, inboxes, batch_size, next_display_id)
    contacts_data = generate_contacts_data(account, batch_size)
    DataTasks.bulk_insert_contacts(contacts_data)

    new_contacts = Contact.where(account_id: account.id)
                          .order(created_at: :desc)
                          .limit(batch_size)

    contact_inboxes_data = generate_contact_inboxes_data(new_contacts, inboxes)
    DataTasks.bulk_insert_contact_inboxes(contact_inboxes_data)

    contact_inboxes = ContactInbox.where(contact_id: new_contacts.pluck(:id))

    conversations_data = generate_conversations_data(account, contact_inboxes, next_display_id)
    process_conversations(conversations_data)
  end

  def generate_contacts_data(account, batch_size)
    Array.new(batch_size) do
      created_at = Faker::Time.between(from: 1.year.ago, to: Time.current)
      {
        account_id: account.id,
        name: Faker::Name.name,
        email: "#{SecureRandom.uuid}@example.com",
        phone_number: rand < 0.7 ? Faker::PhoneNumber.cell_phone : nil,
        additional_attributes: generate_additional_attributes,
        created_at: created_at,
        updated_at: created_at
      }
    end
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

  def process_conversations(conversations_data)
    conversations_data.each_slice(5000) do |batch|
      DataTasks.bulk_insert_conversations(batch)
    end
  end
end

# Move task logic to a separate service class
class TestDataGenerationService
  class << self
    def bulk_insert_contacts(contacts_data)
      contacts_data.each_slice(1000) do |batch|
        Contact.transaction do
          batch.each { |data| Contact.create!(data) }
        end
      end
    end

    def bulk_insert_contact_inboxes(contact_inboxes_data)
      contact_inboxes_data.each_slice(1000) do |batch|
        ContactInbox.transaction do
          batch.each { |data| ContactInbox.create!(data) }
        end
      end
    end

    def bulk_insert_conversations(conversations_data)
      conversations_data.each_slice(1000) do |batch|
        Conversation.transaction do
          batch.each { |data| Conversation.create!(data) }
        end
      end
    end

    def generate_test_data
      puts "Starting to generate distributed test data across #{NUM_ACCOUNTS} accounts..."
      puts "Each account will have #{INBOXES_PER_ACCOUNT} API inboxes"
      puts "Each account will have between #{MIN_MESSAGES / 1_000_000}M and #{MAX_MESSAGES / 1_000_000}M messages"

      (0...NUM_ACCOUNTS).each do |account_index|
        process_account(account_index)
      end

      puts "ALL DONE! Created #{NUM_ACCOUNTS} accounts with distributed test data"
    end

    private

    def process_account(account_index)
      account = create_account(START_ID + account_index)
      inboxes = create_inboxes(account)

      target_message_count, total_contacts_needed = TestDataGenerator.generate_account_data(account)
      process_account_data(account, inboxes, total_contacts_needed, target_message_count)
    end

    def process_account_data(account, inboxes, total_contacts_needed, target_message_count)
      max_display_id = Conversation.where(account_id: account.id).maximum(:display_id) || 0
      next_display_id = max_display_id + 1

      contact_count = 0
      message_count = 0

      while contact_count < total_contacts_needed
        batch_size = [BATCH_SIZE, total_contacts_needed - contact_count].min
        TestDataGenerator.process_contacts_batch(account, inboxes, batch_size, next_display_id)
        contact_count += batch_size
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

    TestDataGenerator.setup_database_optimizations
    TestDataGenerationService.generate_test_data
    TestDataGenerator.restore_database_settings
  end

  desc 'Clean up existing test data'
  task cleanup_test_data: :environment do
    if File.exist?('tmp/test_data_account_ids.txt')
      account_ids = File.read('tmp/test_data_account_ids.txt').split(',')
      Account.where(id: account_ids).destroy_all
      File.delete('tmp/test_data_account_ids.txt')
    end
  end
end
