class TestData::ContactBatchService
  def initialize(account:, inboxes:, batch_size:, display_id_tracker:)
    @account = account
    @inboxes = inboxes
    @batch_size = batch_size
    @display_id_tracker = display_id_tracker
    @total_messages = 0
  end

  # Generates contacts, contact_inboxes, conversations, and messages
  # Returns the total number of messages created in this batch
  def generate!
    Rails.logger.info { "Starting batch generation for account ##{@account.id} with #{@batch_size} contacts" }

    create_contacts
    create_contact_inboxes
    create_conversations
    create_messages

    Rails.logger.info { "Completed batch with #{@total_messages} messages for account ##{@account.id}" }
    @total_messages
  end

  private

  # rubocop:disable Rails/SkipsModelValidations
  def create_contacts
    Rails.logger.info { "Creating #{@batch_size} contacts for account ##{@account.id}" }
    start_time = Time.current

    @contacts_data = Array.new(@batch_size) { build_contact_data }
    Contact.insert_all!(@contacts_data) if @contacts_data.any?
    @contacts = Contact
                .where(account_id: @account.id)
                .order(created_at: :desc)
                .limit(@batch_size)

    Rails.logger.info { "Contacts created in #{Time.current - start_time}s" }
  end
  # rubocop:enable Rails/SkipsModelValidations

  def build_contact_data
    created_at = Faker::Time.between(from: 1.year.ago, to: Time.current)
    {
      account_id: @account.id,
      name: Faker::Name.name,
      email: "#{SecureRandom.uuid}@example.com",
      phone_number: generate_e164_phone_number,
      additional_attributes: maybe_add_additional_attributes,
      created_at: created_at,
      updated_at: created_at
    }
  end

  def maybe_add_additional_attributes
    return unless rand < 0.3

    {
      company: Faker::Company.name,
      city: Faker::Address.city,
      country: Faker::Address.country_code
    }
  end

  def generate_e164_phone_number
    return nil unless rand < 0.7

    country_code = TestData::Constants::COUNTRY_CODES.sample
    subscriber_number = rand(1_000_000..9_999_999_999).to_s
    subscriber_number = subscriber_number[0...(15 - country_code.length)]
    "+#{country_code}#{subscriber_number}"
  end

  # rubocop:disable Rails/SkipsModelValidations
  def create_contact_inboxes
    Rails.logger.info { "Creating contact inboxes for #{@contacts.size} contacts" }
    start_time = Time.current

    contact_inboxes_data = @contacts.flat_map do |contact|
      @inboxes.map do |inbox|
        {
          inbox_id: inbox.id,
          contact_id: contact.id,
          source_id: SecureRandom.uuid,
          created_at: contact.created_at,
          updated_at: contact.created_at
        }
      end
    end

    count = contact_inboxes_data.size
    ContactInbox.insert_all!(contact_inboxes_data) if contact_inboxes_data.any?
    @contact_inboxes = ContactInbox.where(contact_id: @contacts.pluck(:id))

    Rails.logger.info { "Created #{count} contact inboxes in #{Time.current - start_time}s" }
  end
  # rubocop:enable Rails/SkipsModelValidations

  # rubocop:disable Rails/SkipsModelValidations
  def create_conversations
    Rails.logger.info { "Creating conversations for account ##{@account.id}" }
    start_time = Time.current

    conversations_data = []
    @contact_inboxes.each do |ci|
      num_convos = rand(1..TestData::Constants::MAX_CONVERSATIONS_PER_CONTACT)
      num_convos.times { conversations_data << build_conversation(ci) }
    end

    count = conversations_data.size
    Rails.logger.info { "Preparing to insert #{count} conversations" }

    Conversation.insert_all!(conversations_data) if conversations_data.any?
    @conversations = Conversation.where(
      account_id: @account.id,
      display_id: conversations_data.pluck(:display_id)
    ).order(:created_at)

    Rails.logger.info { "Created #{count} conversations in #{Time.current - start_time}s" }
  end
  # rubocop:enable Rails/SkipsModelValidations

  def build_conversation(contact_inbox)
    created_at = Faker::Time.between(from: contact_inbox.created_at, to: Time.current)
    {
      account_id: @account.id,
      inbox_id: contact_inbox.inbox_id,
      contact_id: contact_inbox.contact_id,
      contact_inbox_id: contact_inbox.id,
      status: TestData::Constants::STATUSES.sample,
      created_at: created_at,
      updated_at: created_at,
      display_id: @display_id_tracker.next_id
    }
  end

  # rubocop:disable Rails/SkipsModelValidations
  def create_messages
    Rails.logger.info { "Creating messages for #{@conversations.size} conversations" }
    start_time = Time.current

    batch_count = 0
    @conversations.find_in_batches(batch_size: 1000) do |batch|
      batch_count += 1
      batch_start = Time.current

      messages_data = batch.flat_map do |convo|
        build_messages_for_conversation(convo)
      end

      batch_message_count = messages_data.size
      Rails.logger.info { "Preparing to insert #{batch_message_count} messages (batch #{batch_count})" }

      Message.insert_all!(messages_data) if messages_data.any?
      @total_messages += batch_message_count

      Rails.logger.info { "Created batch #{batch_count} with #{batch_message_count} messages in #{Time.current - batch_start}s" }
    end

    Rails.logger.info { "Created total of #{@total_messages} messages in #{Time.current - start_time}s" }
  end
  # rubocop:enable Rails/SkipsModelValidations

  def build_messages_for_conversation(conversation)
    num_messages = rand(TestData::Constants::MIN_MESSAGES_PER_CONVO..TestData::Constants::MAX_MESSAGES_PER_CONVO)
    message_type = TestData::Constants::MESSAGE_TYPES.sample
    time_range = [conversation.created_at, Time.current]
    generate_messages(conversation, num_messages, message_type, time_range)
  end

  def generate_messages(conversation, num_messages, initial_message_type, time_range)
    message_type = initial_message_type

    Array.new(num_messages) do
      message_type = (message_type == 'incoming' ? 'outgoing' : 'incoming')
      created_at = Faker::Time.between(from: time_range.first, to: time_range.last)
      build_message_data(conversation, message_type, created_at)
    end
  end

  def build_message_data(conversation, message_type, created_at)
    {
      account_id: @account.id,
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
end
