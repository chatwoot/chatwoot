# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationRecord do
  it_behaves_like 'encrypted external credential',
                  factory: :channel_email,
                  attribute: :smtp_password,
                  value: 'smtp-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_email,
                  attribute: :imap_password,
                  value: 'imap-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_twilio_sms,
                  attribute: :auth_token,
                  value: 'twilio-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :integrations_hook,
                  attribute: :access_token,
                  value: 'hook-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_facebook_page,
                  attribute: :page_access_token,
                  value: 'fb-page-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_facebook_page,
                  attribute: :user_access_token,
                  value: 'fb-user-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_instagram,
                  attribute: :access_token,
                  value: 'ig-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_line,
                  attribute: :line_channel_secret,
                  value: 'line-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_line,
                  attribute: :line_channel_token,
                  value: 'line-token-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_telegram,
                  attribute: :bot_token,
                  value: 'telegram-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_twitter_profile,
                  attribute: :twitter_access_token,
                  value: 'twitter-access-secret'

  it_behaves_like 'encrypted external credential',
                  factory: :channel_twitter_profile,
                  attribute: :twitter_access_token_secret,
                  value: 'twitter-secret-secret'

  context 'when backfilling legacy plaintext' do
    before do
      skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?
    end

    it 'reads existing plaintext and encrypts on update' do
      account = create(:account)
      channel = create(:channel_email, account: account, smtp_password: nil)

      # Simulate legacy plaintext by updating the DB directly
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        ['UPDATE channel_email SET smtp_password = ? WHERE id = ?', 'legacy-plain', channel.id]
      )
      ActiveRecord::Base.connection.execute(sql)

      legacy_record = Channel::Email.find(channel.id)
      expect(legacy_record.smtp_password).to eq('legacy-plain')

      legacy_record.update!(smtp_password: 'encrypted-now')

      stored_value = legacy_record.reload.read_attribute_before_type_cast(:smtp_password)
      expect(stored_value).to be_present
      expect(stored_value).not_to include('encrypted-now')
      expect(legacy_record.smtp_password).to eq('encrypted-now')
    end
  end

  context 'when looking up telegram legacy records' do
    before do
      skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?
    end

    it 'finds plaintext records via fallback lookup' do
      channel = create(:channel_telegram, bot_token: 'legacy-token')

      # Simulate legacy plaintext by updating the DB directly
      sql = ActiveRecord::Base.send(
        :sanitize_sql_array,
        ['UPDATE channel_telegram SET bot_token = ? WHERE id = ?', 'legacy-token', channel.id]
      )
      ActiveRecord::Base.connection.execute(sql)

      found = Channel::Telegram.find_by(bot_token: 'legacy-token')
      expect(found).to eq(channel)
    end
  end
end
