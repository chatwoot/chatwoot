namespace :data do
  desc 'Generate distributed test data across 20 accounts with 1M-10M messages each and realistic patterns'
  task generate_distributed_data: :environment do
    NUM_ACCOUNTS = 20
    MIN_MESSAGES = 1_000_000  # 1M
    MAX_MESSAGES = 10_000_000 # 10M
    BATCH_SIZE = 5_000  # Increased batch size
    START_ID = 10
    MAX_CONVERSATIONS_PER_CONTACT = 20
    INBOXES_PER_ACCOUNT = 5  # Number of API inboxes per account
    STATUSES = %w[open resolved pending].freeze
    MESSAGE_TYPES = %w[incoming outgoing].freeze
    MIN_MESSAGES_PER_CONVO = 5
    MAX_MESSAGES_PER_CONVO = 50

    if Rails.env.production?
      puts "Generating large amounts of data in production can have serious performance implications."
      puts "Exiting to avoid impacting a live environment."
      exit
    end
    
    # Performance optimizations
    ActiveRecord::Base.logger = nil  # Disable SQL logging
    ActiveRecord::Base.connection.execute('SET statement_timeout = 0')
    ActiveRecord::Base.connection.execute('SET synchronous_commit = off')  # Faster commits
    ActiveRecord::Base.connection.execute('ALTER TABLE conversations DISABLE TRIGGER ALL')
    ActiveRecord::Base.connection.execute('ALTER TABLE messages DISABLE TRIGGER ALL')
    
    puts "Starting to generate distributed test data across #{NUM_ACCOUNTS} accounts..."
    puts "Each account will have #{INBOXES_PER_ACCOUNT} API inboxes"
    puts "Each account will have between #{MIN_MESSAGES/1_000_000}M and #{MAX_MESSAGES/1_000_000}M messages"
    
    (0...NUM_ACCOUNTS).each do |account_index|
      account_number = START_ID + account_index
      
      # Create account
      account = Account.find_or_create_by!(id: account_number) do |acct|
        company_type = rand < 0.3 ? 'Tech' : ['Retail', 'Healthcare', 'Finance', 'Education', 'Manufacturing'].sample
        company_name = if rand < 0.4
          "#{Faker::Company.name} #{company_type}"
        elsif rand < 0.7
          "#{Faker::App.name} #{company_type}"
        else
          "#{Faker::ProgrammingLanguage.name.capitalize} #{Faker::Company.suffix}"
        end
        
        acct.name = company_name
        acct.domain = "#{company_name.downcase.gsub(/[^a-z0-9]/, '-')}.#{['com', 'io', 'tech', 'ai'].sample}"
      end
      
      # Create multiple API inboxes
      inboxes = INBOXES_PER_ACCOUNT.times.map do |i|
        account.inboxes.create!(
          name: "API Inbox #{i + 1}",
          channel: Channel::Api.create!(account: account)
        )
      end
      
      # Determine message volume
      target_message_count = rand(MIN_MESSAGES..MAX_MESSAGES)
      avg_msgs_per_conversation = rand(15..50)
      
      # Calculate needed conversations and contacts
      total_conversations_needed = (target_message_count / avg_msgs_per_conversation.to_f).ceil
      total_contacts_needed = (total_conversations_needed / MAX_CONVERSATIONS_PER_CONTACT.to_f).ceil
      
      puts "==> Creating Account ##{account.id} with target of #{target_message_count/1_000_000}M messages"
      puts "    Planning for #{total_contacts_needed} contacts and #{total_conversations_needed} conversations"
      
      # Find max display_id for this account
      max_display_id = Conversation.where(account_id: account.id).maximum(:display_id) || 0
      next_display_id = max_display_id + 1
      
      contact_count = 0
      message_count = 0
      
      while contact_count < total_contacts_needed
        batch_size = [BATCH_SIZE, total_contacts_needed - contact_count].min
        
        # Bulk create contacts with pre-generated data
        contacts_data = batch_size.times.map do
          created_at = Faker::Time.between(from: 1.year.ago, to: Time.current)
          {
            account_id: account.id,
            name: Faker::Name.name,
            email: "#{SecureRandom.uuid}@example.com",
            phone_number: rand < 0.7 ? Faker::PhoneNumber.cell_phone : nil,
            additional_attributes: rand < 0.3 ? {
              company: Faker::Company.name,
              city: Faker::Address.city,
              country: Faker::Address.country_code
            } : nil,
            created_at: created_at,
            updated_at: created_at
          }
        end
        
        Contact.insert_all!(contacts_data)
        
        # Get created contacts
        new_contacts = Contact.where(account_id: account.id)
                            .order(created_at: :desc)
                            .limit(batch_size)
        
        # Bulk create contact inboxes for all API inboxes
        contact_inboxes_data = []
        new_contacts.each do |contact|
          inboxes.each do |inbox|
            contact_inboxes_data << {
              inbox_id: inbox.id,
              contact_id: contact.id,
              source_id: SecureRandom.uuid,
              created_at: contact.created_at,
              updated_at: contact.created_at
            }
          end
        end
        
        ContactInbox.insert_all!(contact_inboxes_data)
        
        # Get created contact inboxes
        contact_inboxes = ContactInbox.where(contact_id: new_contacts.pluck(:id))
        
        # Bulk create conversations with distributed inboxes
        conversations_data = []
        contact_inboxes.each do |contact_inbox|
          num_conversations = rand(1..MAX_CONVERSATIONS_PER_CONTACT)
          num_conversations.times do
            created_at = Faker::Time.between(from: contact_inbox.created_at, to: Time.current)
            conversations_data << {
              account_id: account.id,
              inbox_id: contact_inbox.inbox_id,  # Use the inbox from contact_inbox
              contact_id: contact_inbox.contact_id,
              contact_inbox_id: contact_inbox.id,
              status: STATUSES.sample,
              display_id: next_display_id += 1,
              created_at: created_at,
              updated_at: created_at
            }
          end
        end
        
        # Insert conversations in larger batches
        conversations_data.each_slice(5000) do |batch|
          Conversation.insert_all!(batch)
        end
        
        # Get created conversations and bulk create messages
        new_conversations = Conversation.where(account_id: account.id)
                                      .order(created_at: :desc)
                                      .limit(conversations_data.size)
        
        messages_data = []
        new_conversations.each do |conversation|
          num_messages = rand(MIN_MESSAGES_PER_CONVO..MAX_MESSAGES_PER_CONVO)
          message_time = conversation.created_at
          
          num_messages.times do |i|
            is_customer_message = i == 0 || rand < 0.5
            message_time += rand(30..3600).seconds
            
            messages_data << {
              account_id: account.id,
              inbox_id: conversation.inbox_id,
              conversation_id: conversation.id,
              message_type: is_customer_message ? 'incoming' : 'outgoing',
              content: Faker::Lorem.sentence(word_count: rand(3..30)),
              content_type: 'text',
              status: 'sent',
              sender_type: is_customer_message ? 'Contact' : 'User',
              sender_id: is_customer_message ? conversation.contact_id : 1,
              created_at: message_time,
              updated_at: message_time
            }
            
            # Bulk insert in larger batches
            if messages_data.size >= 5000
              Message.insert_all!(messages_data)
              message_count += messages_data.size
              messages_data = []
            end
          end
        end
        
        # Insert remaining messages
        if messages_data.any?
          Message.insert_all!(messages_data)
          message_count += messages_data.size
        end
        
        contact_count += batch_size
        puts "    Created #{contact_count}/#{total_contacts_needed} contacts, #{message_count}/#{target_message_count} messages"
      end
      
      puts "==> Completed Account ##{account.id} with #{message_count} messages"
    end
    
    # Re-enable database optimizations
    ActiveRecord::Base.connection.execute('SET synchronous_commit = on')
    ActiveRecord::Base.connection.execute('ALTER TABLE conversations ENABLE TRIGGER ALL')
    ActiveRecord::Base.connection.execute('ALTER TABLE messages ENABLE TRIGGER ALL')
    
    puts "ALL DONE! Created #{NUM_ACCOUNTS} accounts with distributed test data"
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