# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  it { is_expected.to have_many(:users).through(:account_users) }
  it { is_expected.to have_many(:account_users) }
  it { is_expected.to have_many(:inboxes).dependent(:destroy_async) }
  it { is_expected.to have_many(:conversations).dependent(:destroy_async) }
  it { is_expected.to have_many(:contacts).dependent(:destroy_async) }
  it { is_expected.to have_many(:telegram_bots).dependent(:destroy_async) }
  it { is_expected.to have_many(:canned_responses).dependent(:destroy_async) }
  it { is_expected.to have_many(:facebook_pages).class_name('::Channel::FacebookPage').dependent(:destroy_async) }
  it { is_expected.to have_many(:web_widgets).class_name('::Channel::WebWidget').dependent(:destroy_async) }
  it { is_expected.to have_many(:webhooks).dependent(:destroy_async) }
  it { is_expected.to have_many(:notification_settings).dependent(:destroy_async) }
  it { is_expected.to have_many(:reporting_events) }
  it { is_expected.to have_many(:portals).dependent(:destroy_async) }
  it { is_expected.to have_many(:categories).dependent(:destroy_async) }
  it { is_expected.to have_many(:teams).dependent(:destroy_async) }

  # This validation happens in ApplicationRecord
  describe 'length validations' do
    let(:account) { create(:account) }

    it 'validates name length' do
      account.name = 'a' * 256
      account.valid?
      expect(account.errors[:name]).to include('is too long (maximum is 255 characters)')
    end

    it 'validates domain length' do
      account.domain = 'a' * 150
      account.valid?
      expect(account.errors[:domain]).to include('is too long (maximum is 100 characters)')
    end
  end

  describe 'usage_limits' do
    let(:account) { create(:account) }

    it 'returns ChatwootApp.max limits' do
      expect(account.usage_limits[:agents]).to eq(ChatwootApp.max_limit)
      expect(account.usage_limits[:inboxes]).to eq(ChatwootApp.max_limit)
    end
  end

  describe 'inbound_email_domain' do
    let(:account) { create(:account) }

    it 'returns the domain from inbox if inbox value is present' do
      account.update!(domain: 'test.com')
      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'test2.com' do
        expect(account.inbound_email_domain).to eq('test.com')
      end
    end

    it 'returns the domain from ENV if inbox value is nil' do
      account.update!(domain: nil)
      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'test.com' do
        expect(account.inbound_email_domain).to eq('test.com')
      end
    end

    it 'returns the domain from ENV if inbox value is empty string' do
      account.update!(domain: '')
      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'test.com' do
        expect(account.inbound_email_domain).to eq('test.com')
      end
    end
  end

  describe 'support_email' do
    let(:account) { create(:account) }

    it 'returns the support email from inbox if inbox value is present' do
      account.update!(support_email: 'support@chatwoot.com')
      with_modified_env MAILER_SENDER_EMAIL: 'hello@chatwoot.com' do
        expect(account.support_email).to eq('support@chatwoot.com')
      end
    end

    it 'returns the support email from ENV if inbox value is nil' do
      account.update!(support_email: nil)
      with_modified_env MAILER_SENDER_EMAIL: 'hello@chatwoot.com' do
        expect(account.support_email).to eq('hello@chatwoot.com')
      end
    end

    it 'returns the support email from ENV if inbox value is empty string' do
      account.update!(support_email: '')
      with_modified_env MAILER_SENDER_EMAIL: 'hello@chatwoot.com' do
        expect(account.support_email).to eq('hello@chatwoot.com')
      end
    end
  end

  context 'when after_destroy is called' do
    it 'conv_dpid_seq and camp_dpid_seq_ are deleted' do
      account = create(:account)
      query = "select * from information_schema.sequences where sequence_name in  ('camp_dpid_seq_#{account.id}', 'conv_dpid_seq_#{account.id}');"
      expect(ActiveRecord::Base.connection.execute(query).count).to eq(2)
      expect(account.locale).to eq('en')
      account.destroy!
      expect(ActiveRecord::Base.connection.execute(query).count).to eq(0)
    end
  end

  describe 'locale' do
    it 'returns correct language if the value is set' do
      account = create(:account, locale: 'fr')
      expect(account.locale).to eq('fr')
      expect(account.locale_english_name).to eq('french')
    end

    it 'returns english if the value is not set' do
      account = create(:account, locale: nil)
      expect(account.locale).to be_nil
      expect(account.locale_english_name).to eq('english')
    end

    it 'returns english if the value is empty string' do
      account = create(:account, locale: '')
      expect(account.locale).to be_nil
      expect(account.locale_english_name).to eq('english')
    end

    it 'returns correct language if the value has country code' do
      account = create(:account, locale: 'pt_BR')
      expect(account.locale).to eq('pt_BR')
      expect(account.locale_english_name).to eq('portuguese')
    end
  end

  describe 'settings' do
    let(:account) { create(:account) }

    context 'when auto_resolve_after' do
      it 'validates minimum value' do
        account.settings = { auto_resolve_after: 4 }
        expect(account).to be_invalid
        expect(account.errors.messages).to eq({ auto_resolve_after: ['must be greater than or equal to 10'] })
      end

      it 'validates maximum value' do
        account.settings = { auto_resolve_after: 1_439_857 }
        expect(account).to be_invalid
        expect(account.errors.messages).to eq({ auto_resolve_after: ['must be less than or equal to 1439856'] })
      end

      it 'allows valid values' do
        account.settings = { auto_resolve_after: 15 }
        expect(account).to be_valid

        account.settings = { auto_resolve_after: 1_439_856 }
        expect(account).to be_valid
      end

      it 'allows null values' do
        account.settings = { auto_resolve_after: nil }
        expect(account).to be_valid
      end
    end

    context 'when auto_resolve_message' do
      it 'allows string values' do
        account.settings = { auto_resolve_message: 'This conversation has been resolved automatically.' }
        expect(account).to be_valid
      end

      it 'allows empty string' do
        account.settings = { auto_resolve_message: '' }
        expect(account).to be_valid
      end

      it 'allows nil values' do
        account.settings = { auto_resolve_message: nil }
        expect(account).to be_valid
      end
    end

    context 'when using store_accessor' do
      it 'correctly gets and sets auto_resolve_after' do
        account.auto_resolve_after = 30
        expect(account.auto_resolve_after).to eq(30)
        expect(account.settings['auto_resolve_after']).to eq(30)
      end

      it 'correctly gets and sets auto_resolve_message' do
        message = 'This conversation was automatically resolved'
        account.auto_resolve_message = message
        expect(account.auto_resolve_message).to eq(message)
        expect(account.settings['auto_resolve_message']).to eq(message)
      end

      it 'handles nil values correctly' do
        account.auto_resolve_after = nil
        account.auto_resolve_message = nil
        expect(account.auto_resolve_after).to be_nil
        expect(account.auto_resolve_message).to be_nil
      end
    end

    context 'when using with_auto_resolve scope' do
      it 'finds accounts with auto_resolve_after set' do
        account.update!(auto_resolve_after: 40 * 24 * 60)
        expect(described_class.with_auto_resolve).to include(account)
      end

      it 'does not find accounts without auto_resolve_after' do
        account.update!(auto_resolve_after: nil)
        expect(described_class.with_auto_resolve).not_to include(account)
      end
    end
  end
end
