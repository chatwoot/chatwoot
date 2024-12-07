# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Account do
  it { is_expected.to validate_numericality_of(:auto_resolve_duration).is_greater_than_or_equal_to(1) }
  it { is_expected.to validate_numericality_of(:auto_resolve_duration).is_less_than_or_equal_to(999) }

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
      expect(account.usage_limits).to eq({ agents: ChatwootApp.max_limit, inboxes: ChatwootApp.max_limit })
    end
  end

  describe 'inbound_email_domain' do
    let(:account) { create(:account) }

    it 'returns the domain from inbox if inbox value is present' do
      account.update(domain: 'test.com')
      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'test2.com' do
        expect(account.inbound_email_domain).to eq('test.com')
      end
    end

    it 'returns the domain from ENV if inbox value is nil' do
      account.update(domain: nil)
      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'test.com' do
        expect(account.inbound_email_domain).to eq('test.com')
      end
    end

    it 'returns the domain from ENV if inbox value is empty string' do
      account.update(domain: '')
      with_modified_env MAILER_INBOUND_EMAIL_DOMAIN: 'test.com' do
        expect(account.inbound_email_domain).to eq('test.com')
      end
    end
  end

  describe 'support_email' do
    let(:account) { create(:account) }

    it 'returns the support email from inbox if inbox value is present' do
      account.update(support_email: 'support@chatwoot.com')
      with_modified_env MAILER_SENDER_EMAIL: 'hello@chatwoot.com' do
        expect(account.support_email).to eq('support@chatwoot.com')
      end
    end

    it 'returns the support email from ENV if inbox value is nil' do
      account.update(support_email: nil)
      with_modified_env MAILER_SENDER_EMAIL: 'hello@chatwoot.com' do
        expect(account.support_email).to eq('hello@chatwoot.com')
      end
    end

    it 'returns the support email from ENV if inbox value is empty string' do
      account.update(support_email: '')
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
      account.destroy
      expect(ActiveRecord::Base.connection.execute(query).count).to eq(0)
    end
  end
end
