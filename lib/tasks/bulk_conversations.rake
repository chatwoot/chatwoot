namespace :conversations do
  desc 'Generate bulk conversations with contacts and movie dialogue messages'
  task :generate_bulk, [:count, :account_id, :inbox_id] => :environment do |_t, args|
    if Rails.env.production?
      puts 'Generating bulk data in production can have serious performance implications.'
      puts 'Exiting to avoid impacting a live environment.'
      exit
    end

    count = (args[:count] || ENV['COUNT'] || 10).to_i
    account_id = args[:account_id] || ENV['ACCOUNT_ID']
    inbox_id = args[:inbox_id] || ENV['INBOX_ID']

    if account_id.blank?
      puts 'Error: ACCOUNT_ID is required'
      puts 'Usage: bundle exec rake conversations:generate_bulk[count,account_id,inbox_id]'
      puts 'Or: COUNT=100 ACCOUNT_ID=1 INBOX_ID=1 bundle exec rake conversations:generate_bulk'
      exit(1)
    end

    if inbox_id.blank?
      puts 'Error: INBOX_ID is required'
      puts 'Usage: bundle exec rake conversations:generate_bulk[count,account_id,inbox_id]'
      puts 'Or: COUNT=100 ACCOUNT_ID=1 INBOX_ID=1 bundle exec rake conversations:generate_bulk'
      exit(1)
    end

    account = Account.find_by(id: account_id)
    inbox = Inbox.find_by(id: inbox_id)

    unless account
      puts "Error: Account with ID #{account_id} not found"
      exit(1)
    end

    unless inbox
      puts "Error: Inbox with ID #{inbox_id} not found"
      exit(1)
    end

    unless inbox.account_id == account.id
      puts "Error: Inbox #{inbox_id} does not belong to Account #{account_id}"
      exit(1)
    end

    puts "Generating #{count} conversations for Account ##{account.id} in Inbox ##{inbox.id}..."
    puts "Started at: #{Time.current}"

    start_time = Time.current
    created_count = 0

    count.times do |i|
      contact = create_contact(account)
      contact_inbox = create_contact_inbox(contact, inbox)
      conversation = create_conversation(contact_inbox)
      add_messages(conversation)

      created_count += 1
      puts "Created conversation #{i + 1}/#{count} (ID: #{conversation.id})" if (i + 1) % 10 == 0
    rescue StandardError => e
      puts "Error creating conversation #{i + 1}: #{e.message}"
      puts e.backtrace.first(5).join("\n")
    end

    elapsed_time = Time.current - start_time
    puts "\nCompleted!"
    puts "Successfully created: #{created_count} conversations"
    puts "Total time: #{elapsed_time.round(2)}s"
    puts "Average time per conversation: #{(elapsed_time / created_count).round(3)}s" if created_count.positive?
  end

  def create_contact(account)
    Contact.create!(
      account: account,
      name: Faker::Name.name,
      email: "#{SecureRandom.uuid}@example.com",
      phone_number: generate_e164_phone_number,
      additional_attributes: {
        source: 'bulk_generator',
        company: Faker::Company.name,
        city: Faker::Address.city
      }
    )
  end

  def generate_e164_phone_number
    country_code = [1, 44, 61, 91, 81].sample
    subscriber_number = rand(1_000_000..9_999_999_999).to_s
    subscriber_number = subscriber_number[0...(15 - country_code.to_s.length)]
    "+#{country_code}#{subscriber_number}"
  end

  def create_contact_inbox(contact, inbox)
    ContactInboxBuilder.new(
      contact: contact,
      inbox: inbox
    ).perform
  end

  def create_conversation(contact_inbox)
    ConversationBuilder.new(
      params: ActionController::Parameters.new(
        status: %w[open resolved pending].sample,
        additional_attributes: {},
        custom_attributes: {}
      ),
      contact_inbox: contact_inbox
    ).perform
  end

  def add_messages(conversation)
    num_messages = rand(3..10)
    message_type = %w[incoming outgoing].sample

    num_messages.times do
      message_type = message_type == 'incoming' ? 'outgoing' : 'incoming'
      create_message(conversation, message_type)
    end
  end

  def create_message(conversation, message_type)
    sender = if message_type == 'incoming'
               conversation.contact
             else
               conversation.account.users.sample || conversation.account.administrators.first
             end

    conversation.messages.create!(
      account: conversation.account,
      inbox: conversation.inbox,
      sender: sender,
      message_type: message_type,
      content: generate_movie_dialogue,
      content_type: :text,
      private: false
    )
  end

  def generate_movie_dialogue
    Faker::Movie.quote
  end
end
