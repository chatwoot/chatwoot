module TestData
  class ContactBatchService
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
      create_contacts
      create_contact_inboxes
      create_conversations
      create_messages
      @total_messages
    end

    private

    def create_contacts
      @contacts_data = Array.new(@batch_size) { build_contact_data }
      Contact.insert_all!(@contacts_data) if @contacts_data.any?
      @contacts = Contact
                  .where(account_id: @account.id)
                  .order(created_at: :desc)
                  .limit(@batch_size)
    end

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

      country_code = Constants::COUNTRY_CODES.sample
      subscriber_number = rand(1_000_000..9_999_999_999).to_s
      subscriber_number = subscriber_number[0...(15 - country_code.length)]
      "+#{country_code}#{subscriber_number}"
    end

    def create_contact_inboxes
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
      ContactInbox.insert_all!(contact_inboxes_data) if contact_inboxes_data.any?
      @contact_inboxes = ContactInbox.where(contact_id: @contacts.pluck(:id))
    end

    def create_conversations
      conversations_data = []
      @contact_inboxes.each do |ci|
        num_convos = rand(1..Constants::MAX_CONVERSATIONS_PER_CONTACT)
        num_convos.times { conversations_data << build_conversation(ci) }
      end

      Conversation.insert_all!(conversations_data) if conversations_data.any?
      @conversations = Conversation.where(
        account_id: @account.id,
        display_id: conversations_data.map { |c| c[:display_id] }
      ).order(:created_at)
    end

    def build_conversation(contact_inbox)
      created_at = Faker::Time.between(from: contact_inbox.created_at, to: Time.current)
      {
        account_id: @account.id,
        inbox_id: contact_inbox.inbox_id,
        contact_id: contact_inbox.contact_id,
        contact_inbox_id: contact_inbox.id,
        status: Constants::STATUSES.sample,
        created_at: created_at,
        updated_at: created_at,
        display_id: @display_id_tracker.next_id
      }
    end

    def create_messages
      @conversations.find_in_batches(batch_size: 1000) do |batch|
        messages_data = batch.flat_map do |convo|
          build_messages_for_conversation(convo)
        end
        Message.insert_all!(messages_data) if messages_data.any?
        @total_messages += messages_data.size
      end
    end

    def build_messages_for_conversation(conversation)
      num_messages = rand(Constants::MIN_MESSAGES_PER_CONVO..Constants::MAX_MESSAGES_PER_CONVO)
      message_type = Constants::MESSAGE_TYPES.sample
      time_range = [conversation.created_at, Time.current]

      Array.new(num_messages) do
        message_type = (message_type == 'incoming' ? 'outgoing' : 'incoming')
        created_at = Faker::Time.between(from: time_range.first, to: time_range.last)
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
  end
end
