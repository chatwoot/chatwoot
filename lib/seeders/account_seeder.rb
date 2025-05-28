## Class to generate sample data for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::AccountSeeder.new(account: Account.find(1)).perform!
#
#
############################################################

class Seeders::AccountSeeder
  def initialize(account:)
    raise 'Account Seeding is not allowed.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account_data = ActiveSupport::HashWithIndifferentAccess.new(YAML.safe_load(Rails.root.join('lib/seeders/seed_data.yml').read))
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

      add_user_to_teams(user: user_record, teams: user['team'])
    end
  end

  def add_user_to_teams(user:, teams:)
    teams.each do |team|
      team_record = @account.teams.where('name LIKE ?', "%#{team.downcase}%").first if team.present?
      TeamMember.find_or_create_by!(team_id: team_record.id, user_id: user.id) unless team_record.nil?
    end
  end

  def seed_canned_responses(count: 50)
    count.times do
      @account.canned_responses.create(content: Faker::Quote.fortune_cookie, short_code: Faker::Alphanumeric.alpha(number: 10))
    end
  end

  def seed_contacts
    @account_data['contacts'].each do |contact_data|
      contact = @account.contacts.find_or_initialize_by(email: contact_data['email'])
      if contact.new_record?
        contact.update!(contact_data.slice('name', 'email'))
        Avatar::AvatarFromUrlJob.perform_later(contact, "https://xsgames.co/randomusers/avatar.php?g=#{contact_data['gender']}")
      end
      contact_data['conversations'].each do |conversation_data|
        inbox = @account.inboxes.find_by(channel_type: conversation_data['channel'])
        contact_inbox = inbox.contact_inboxes.create_or_find_by!(contact: contact, source_id: (conversation_data['source_id'] || SecureRandom.hex))
        create_conversation(contact_inbox: contact_inbox, conversation_data: conversation_data)
      end
    end
  end

  def create_conversation(contact_inbox:, conversation_data:)
    assignee = User.from_email(conversation_data['assignee']) if conversation_data['assignee'].present?
    conversation = contact_inbox.conversations.create!(account: contact_inbox.inbox.account, contact: contact_inbox.contact,
                                                       inbox: contact_inbox.inbox, assignee: assignee)
    create_messages(conversation: conversation, messages: conversation_data['messages'])
    conversation.update_labels(conversation_data[:labels]) if conversation_data[:labels].present?
    conversation.update!(priority: conversation_data[:priority]) if conversation_data[:priority].present?
  end

  def create_messages(conversation:, messages:)
    messages.each do |message_data|
      sender = find_message_sender(conversation, message_data)
      conversation.messages.create!(
        message_data.slice('content', 'message_type').merge(
          account: conversation.inbox.account, sender: sender, inbox: conversation.inbox
        )
      )
    end
  end

  def find_message_sender(conversation, message_data)
    if message_data['message_type'] == 'incoming'
      conversation.contact
    elsif message_data['sender'].present?
      User.from_email(message_data['sender'])
    end
  end

  def seed_inboxes
    Seeders::InboxSeeder.new(account: @account, company_data: @account_data[:company]).perform!
  end
end
