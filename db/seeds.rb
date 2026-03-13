# loading installation configs
GlobalConfig.clear_cache
ConfigLoader.new.process

## Seeds productions
if Rails.env.production?
  # Setup Onboarding flow
  Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
end

## Seeds for Local Development
unless Rails.env.production?

  # Enables creating additional accounts from dashboard
  installation_config = InstallationConfig.find_by(name: 'CREATE_NEW_ACCOUNT_FROM_DASHBOARD')
  installation_config.value = true
  installation_config.save!
  GlobalConfig.clear_cache

  account = Account.find_or_create_by!(name: 'Acme Inc')

  secondary_account = Account.find_or_create_by!(name: 'Acme Org')

  user = User.find_or_initialize_by(email: 'john@acme.inc')
  if user.new_record?
    user.name = 'John'
    user.password = 'Password1!'
    user.type = 'SuperAdmin'
    user.skip_confirmation!
    user.save!
  end

  AccountUser.find_or_create_by!(account_id: account.id, user_id: user.id) { |au| au.role = :administrator }
  AccountUser.find_or_create_by!(account_id: secondary_account.id, user_id: user.id) { |au| au.role = :administrator }

  web_widget = Channel::WebWidget.find_or_create_by!(account: account, website_url: 'https://acme.inc')

  inbox = Inbox.find_or_create_by!(channel: web_widget, account: account) { |i| i.name = 'Acme Support' }
  InboxMember.find_or_create_by!(user: user, inbox: inbox)

  contact_inbox = ContactInboxWithContactBuilder.new(
    source_id: user.id,
    inbox: inbox,
    hmac_verified: true,
    contact_attributes: { name: 'jane', email: 'jane@example.com', phone_number: '+2320000' }
  ).perform

  conversation = Conversation.find_or_create_by!(account: account, inbox: inbox, contact_inbox: contact_inbox) do |c|
    c.status = :open
    c.assignee = user
    c.contact = contact_inbox.contact
    c.additional_attributes = {}
  end

  if conversation.messages.none?
    # sample email collect
    Seeders::MessageSeeder.create_sample_email_collect_message conversation

    Message.create!(content: 'Hello', account: account, inbox: inbox, conversation: conversation, sender: contact_inbox.contact,
                    message_type: :incoming)

    # sample location message
    location_message = Message.new(content: 'location', account: account, inbox: inbox, sender: contact_inbox.contact, conversation: conversation,
                                   message_type: :incoming)
    location_message.attachments.new(
      account_id: account.id,
      file_type: 'location',
      coordinates_lat: 37.7893768,
      coordinates_long: -122.3895553,
      fallback_title: 'Bay Bridge, San Francisco, CA, USA'
    )
    location_message.save!

    # sample card
    Seeders::MessageSeeder.create_sample_cards_message conversation
    # input select
    Seeders::MessageSeeder.create_sample_input_select_message conversation
    # form
    Seeders::MessageSeeder.create_sample_form_message conversation
    # articles
    Seeders::MessageSeeder.create_sample_articles_message conversation
    # csat
    Seeders::MessageSeeder.create_sample_csat_collect_message conversation
  end

  CannedResponse.find_or_create_by!(account: account, short_code: 'start') { |cr| cr.content = 'Hello welcome to chatwoot.' }

  # Default conversation classifications
  [
    'Sale Won',
    'Sale Lost',
    'Information Only',
    'Support Resolved',
    'Other'
  ].each_with_index do |name, index|
    account.conversation_classifications.find_or_create_by!(name: name) do |c|
      c.position = index
    end
  end
end
