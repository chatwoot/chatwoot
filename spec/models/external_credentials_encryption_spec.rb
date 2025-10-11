# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'External credential encryption' do
  include_examples 'encrypted external credential',
                   factory: :channel_email,
                   attribute: :smtp_password,
                   value: 'smtp-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_email,
                   attribute: :imap_password,
                   value: 'imap-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_twilio_sms,
                   attribute: :auth_token,
                   value: 'twilio-secret'

  include_examples 'encrypted external credential',
                   factory: :integrations_hook,
                   attribute: :access_token,
                   value: 'hook-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_facebook_page,
                   attribute: :page_access_token,
                   value: 'fb-page-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_facebook_page,
                   attribute: :user_access_token,
                   value: 'fb-user-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_instagram,
                   attribute: :access_token,
                   value: 'ig-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_line,
                   attribute: :line_channel_secret,
                   value: 'line-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_line,
                   attribute: :line_channel_token,
                   value: 'line-token-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_telegram,
                   attribute: :bot_token,
                   value: 'telegram-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_twitter_profile,
                   attribute: :twitter_access_token,
                   value: 'twitter-access-secret'

  include_examples 'encrypted external credential',
                   factory: :channel_twitter_profile,
                   attribute: :twitter_access_token_secret,
                   value: 'twitter-secret-secret'

  context 'legacy plaintext backfill' do
    before do
      skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?
    end

    it 'reads existing plaintext and encrypts on update' do
      account = create(:account)
      channel = create(:channel_email, account: account, smtp_password: nil)

      Channel::Email.where(id: channel.id).update_all(smtp_password: 'legacy-plain')

      legacy_record = Channel::Email.find(channel.id)
      expect(legacy_record.smtp_password).to eq('legacy-plain')

      legacy_record.update!(smtp_password: 'encrypted-now')

      stored_value = legacy_record.reload.read_attribute_before_type_cast(:smtp_password)
      expect(stored_value).to be_present
      expect(stored_value).not_to include('encrypted-now')
      expect(legacy_record.smtp_password).to eq('encrypted-now')
    end
  end

  context 'telegram legacy lookups' do
    before do
      skip('encryption keys missing; see run_mfa_spec workflow') unless Chatwoot.encryption_configured?
    end

    it 'finds plaintext records via fallback lookup' do
      channel = create(:channel_telegram, bot_token: 'legacy-token')
      Channel::Telegram.where(id: channel.id).update_all(bot_token: 'legacy-token')

      found = Channel::Telegram.find_by(bot_token: 'legacy-token')
      expect(found).to eq(channel)
    end
  end
end
