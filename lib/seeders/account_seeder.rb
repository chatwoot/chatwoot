## Class to generate sample data for a chatwoot test Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::AccountSeeder.new(account: account).seed!
#
#   # When you want to seed only a specific type of data
#   Seeders::AccountSeeder.new(account: account).seed_canned_responses
#   # Seed specific number of objects
#   Seeders::AccountSeeder.new(account: account).seed_canned_responses(count: 10)
#
############################################################

class Seeders::AccountSeeder
  pattr_initialize [:account!]

  def seed!
    seed_canned_responses
    seed_inboxes
  end

  def seed_canned_responses(count: 50)
    count.times do
      account.canned_responses.create(content: Faker::Quote.fortune_cookie, short_code: Faker::Alphanumeric.alpha(number: 10))
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
    channel = Channel::WebWidget.create!(account: account, website_url: 'https://acme.inc')
    Inbox.create!(channel: channel, account: account, name: 'Acme Website')
  end

  def seed_facebook_inbox
    channel = Channel::FacebookPage.create!(account: account, user_access_token: 'test', page_access_token: 'test', page_id: 'test')
    Inbox.create!(channel: channel, account: account, name: 'Acme Facebook')
  end

  def seed_twitter_inbox
    channel = Channel::TwitterProfile.create!(account: account, twitter_access_token: 'test', twitter_access_token_secret: 'test', profile_id: '123')
    Inbox.create!(channel: channel, account: account, name: 'Acme Twitter')
  end

  def seed_whatsapp_inbox
    channel = Channel::Whatsapp.create!(account: account, phone_number: '+123456789')
    Inbox.create!(channel: channel, account: account, name: 'Acme Whatsapp')
  end

  def seed_sms_inbox
    channel = Channel::Sms.create!(account: account, phone_number: '+123456789')
    Inbox.create!(channel: channel, account: account, name: 'Acme SMS')
  end

  def seed_email_inbox
    channel = Channel::Email.create!(account: account, email: 'test@acme.inc', forward_to_email: 'test_fwd@acme.inc')
    Inbox.create!(channel: channel, account: account, name: 'Acme Email')
  end

  def seed_api_inbox
    channel = Channel::Api.create!(account: account)
    Inbox.create!(channel: channel, account: account, name: 'Acme API')
  end

  def seed_telegram_inbox
    # rubocop:disable Rails/SkipsModelValidations
    Channel::Telegram.insert({ account_id: account.id, bot_name: 'Acme', bot_token: 'test', created_at: Time.now.utc, updated_at: Time.now.utc },
                             returning: %w[id])
    channel = Channel::Telegram.find_by(bot_token: 'test')
    Inbox.create!(channel: channel, account: account, name: 'Acme Telegram')
    # rubocop:enable Rails/SkipsModelValidations
  end

  def seed_line_inbox
    channel = Channel::Line.create!(account: account, line_channel_id: 'test', line_channel_secret: 'test', line_channel_token: 'test')
    Inbox.create!(channel: channel, account: account, name: 'Acme Line')
  end
end
