## Class to generate sample inboxes for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::InboxSeeder.new(account: @Account.find(1), company_data:  {name: 'PaperLayer', doamin: 'paperlayer.test'}).perform!
#
#
############################################################

class Seeders::InboxSeeder
  def initialize(account:, company_data:)
    raise 'Inbox Seeding is not allowed in production.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
    @company_data = company_data
  end

  def perform!
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
    channel = Channel::WebWidget.create!(account: @account, website_url: "https://#{@company_data['domain']}")
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Website")
  end

  def seed_facebook_inbox
    channel = Channel::FacebookPage.create!(account: @account, user_access_token: SecureRandom.hex, page_access_token: SecureRandom.hex,
                                            page_id: SecureRandom.hex)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Facebook")
  end

  def seed_twitter_inbox
    channel = Channel::TwitterProfile.create!(account: @account, twitter_access_token: SecureRandom.hex,
                                              twitter_access_token_secret: SecureRandom.hex, profile_id: '123')
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Twitter")
  end

  def seed_whatsapp_inbox
    # rubocop:disable Rails/SkipsModelValidations
    Channel::Whatsapp.insert(
      {
        account_id: @account.id,
        phone_number: Faker::PhoneNumber.cell_phone_in_e164,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      },
      returning: %w[id]
    )
    # rubocop:enable Rails/SkipsModelValidations

    channel = Channel::Whatsapp.find_by(account_id: @account.id)

    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Whatsapp")
  end

  def seed_sms_inbox
    channel = Channel::Sms.create!(account: @account, phone_number: Faker::PhoneNumber.cell_phone_in_e164)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Mobile")
  end

  def seed_email_inbox
    channel = Channel::Email.create!(account: @account, email: "test#{SecureRandom.hex}@#{@company_data['domain']}",
                                     forward_to_email: "test_fwd#{SecureRandom.hex}@#{@company_data['domain']}")
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Email")
  end

  def seed_api_inbox
    channel = Channel::Api.create!(account: @account)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} API")
  end

  def seed_telegram_inbox
    # rubocop:disable Rails/SkipsModelValidations
    bot_token = SecureRandom.hex
    Channel::Telegram.insert(
      {
        account_id: @account.id,
        bot_name: (@company_data['name']).to_s,
        bot_token: bot_token,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      },
      returning: %w[id]
    )
    channel = Channel::Telegram.find_by(bot_token: bot_token)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Telegram")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def seed_line_inbox
    channel = Channel::Line.create!(account: @account, line_channel_id: SecureRandom.hex, line_channel_secret: SecureRandom.hex,
                                    line_channel_token: SecureRandom.hex)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Line")
  end
end
