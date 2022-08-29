## Class to generate sample data for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::AccountSeeder.new(account: @Account.find(1)).perform!
#
#
############################################################

class Seeders::AccountSeeder
  def initialize(account:)
    raise 'Account Seeding is not allowed in production.' if Rails.env.production?

    @account_data = HashWithIndifferentAccess.new(YAML.safe_load(File.read(Rails.root.join('lib/seeders/seed_data.yml'))))
    @account = account
  end

  def perform!
    set_up_account
    seed_teams
    set_up_users
    seed_labels
    seed_canned_responses
    seed_inboxes
    seed_contacts
  end

  def set_up_account
    @account.teams.destroy_all
    @account.conversations.destroy_all
    @account.labels.destroy_all
    @account.inboxes.destroy_all
    @account.contacts.destroy_all
  end

  def seed_teams
    @account_data['teams'].each do |team_name|
      @account.teams.create!(name: team_name)
    end
  end

  def seed_labels
    @account_data['labels'].each do |label|
      @account.labels.create!(label)
    end
  end

  def set_up_users
    @account_data['users'].each do |user|
      user_record = User.create_with(name: user['name'], password: 'Password1!.').find_or_create_by!(email: (user['email']).to_s)
      user_record.skip_confirmation!
      user_record.save!
      Avatar::AvatarFromUrlJob.perform_later(user_record, "https://xsgames.co/randomusers/avatar.php?g=#{user['gender']}")
      AccountUser.create_with(role: (user['role'] || 'agent')).find_or_create_by!(account_id: @account.id, user_id: user_record.id)
      next if user['team'].blank?

      user['team'].each do |team|
        team_record = @account.teams.where('name LIKE ?', "%#{team.downcase}%").first if team.present?
        TeamMember.find_or_create_by!(team_id: team_record.id, user_id: user_record.id) unless team_record.nil?
      end
    end
  end

  def seed_canned_responses(count: 50)
    count.times do
      @account.canned_responses.create(content: Faker::Quote.fortune_cookie, short_code: Faker::Alphanumeric.alpha(number: 10))
    end
  end

  def seed_contacts
    @account_data['contacts'].each do |contact_data|
      contact = @account.contacts.create!(contact_data.slice('name', 'email'))
      Avatar::AvatarFromUrlJob.perform_later(contact, "https://xsgames.co/randomusers/avatar.php?g=#{contact_data['gender']}")
      contact_data['conversations'].each do |conversation_data|
        inbox = @account.inboxes.find_by(channel_type: conversation_data['channel'])
        contact_inbox = inbox.contact_inboxes.create!(contact: contact, source_id: (conversation_data['source_id'] || SecureRandom.hex))
        assignee = User.find_by(email: conversation_data['assignee']) if conversation_data['assignee'].present?
        conversation = contact_inbox.conversations.create!(account: inbox.account, contact: contact, inbox: inbox, assignee: assignee)
        conversation_data['messages'].each do |message_data|
          sender = User.find_by(email: message_data['sender']) if message_data['sender'].present?
          conversation.messages.create!(message_data.slice('content', 'message_type').merge(account: inbox.account, sender: sender, inbox: inbox))
        end
      end
    end
  end

  def seed_inboxes
    seed_website_inbox
    seed_facebook_inbox
    seed_twitter_inbox
    seed_whatsapp_inbox
    seed_sms_inbox
    seed_email_inbox
    seed_api_inbox
    seed_telegram_inbox
    seed_line_inbox
  end

  def seed_website_inbox
    channel = Channel::WebWidget.create!(account: @account, website_url: "https://#{@account_data['company_name'].downcase}.inc")
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Website")
  end

  def seed_facebook_inbox
    channel = Channel::FacebookPage.create!(account: @account, user_access_token: 'test', page_access_token: 'test', page_id: 'test')
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Facebook")
  end

  def seed_twitter_inbox
    channel = Channel::TwitterProfile.create!(account: @account, twitter_access_token: 'test', twitter_access_token_secret: 'test', profile_id: '123')
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Twitter")
  end

  def seed_whatsapp_inbox
    Channel::Whatsapp.insert(
      {
        account_id: @account.id,
        phone_number: Faker::PhoneNumber.cell_phone_in_e164,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      },
      returning: %w[id]
    )

    channel = Channel::Whatsapp.find_by(account_id: @account.id)

    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Whatsapp")
  end

  def seed_sms_inbox
    channel = Channel::Sms.create!(account: @account, phone_number: Faker::PhoneNumber.cell_phone_in_e164)
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Mobile")
  end

  def seed_email_inbox
    channel = Channel::Email.create!(account: @account, email: "test#{SecureRandom.hex}@#{@account_data['company_name'].downcase}.inc",
                                     forward_to_email: "test_fwd#{SecureRandom.hex}@#{@account_data['company_name'].downcase}.inc")
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Email")
  end

  def seed_api_inbox
    channel = Channel::Api.create!(account: @account)
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} API")
  end

  def seed_telegram_inbox
    # rubocop:disable Rails/SkipsModelValidations
    bot_token = SecureRandom.hex
    Channel::Telegram.insert(
      {
        account_id: @account.id,
        bot_name: (@account_data['company_name']).to_s,
        bot_token: bot_token,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      },
      returning: %w[id]
    )
    channel = Channel::Telegram.find_by(bot_token: bot_token)
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Telegram")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def seed_line_inbox
    channel = Channel::Line.create!(account: @account, line_channel_id: SecureRandom.hex, line_channel_secret: SecureRandom.hex,
                                    line_channel_token: SecureRandom.hex)
    Inbox.create!(channel: channel, account: @account, name: "#{@account_data['company_name']} Line")
  end
end
