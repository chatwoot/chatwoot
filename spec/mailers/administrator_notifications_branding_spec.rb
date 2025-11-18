# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Administrator Notification Mailers' do
  describe 'AccountNotificationMailer#account_deletion_for_inactivity' do
    let(:account) { create(:account) }
    let(:mail) do
      AccountNotificationMailer.account_deletion_for_inactivity(
        account,
        { account_name: 'Test Account', deletion_date: '2024-12-31' }
      )
    end

    context 'with custom brand name' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => 'Custom Support',
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'uses custom brand name in account references' do
        expect(mail.body).to match('your Custom Support account')
        expect(mail.body).not_to match('your Chatwoot account')
      end

      it 'uses custom brand name in login instructions' do
        expect(mail.body).to match('Log in to your Custom Support account')
        expect(mail.body).not_to match('Log in to your Chatwoot account')
      end

      it 'uses custom brand name in signature' do
        expect(mail.body).to match('The Custom Support Team')
        expect(mail.body).not_to match('The Chatwoot Team')
      end
    end

    context 'with default fallback' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => nil,
          'INSTALLATION_NAME' => nil
        })
      end

      it 'uses Chatwoot as fallback' do
        expect(mail.body).to match('your Chatwoot account')
        expect(mail.body).to match('The Chatwoot Team')
      end
    end
  end

  describe 'AccountNotificationMailer#account_deletion_user_initiated' do
    let(:account) { create(:account) }
    let(:mail) do
      AccountNotificationMailer.account_deletion_user_initiated(
        account,
        { account_name: 'Test Account', deletion_date: '2024-12-31' }
      )
    end

    context 'with custom brand name' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => 'Custom Support',
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'uses custom brand name in account references' do
        expect(mail.body).to match('deletion of the Custom Support account')
        expect(mail.body).not_to match('deletion of the Chatwoot account')
      end

      it 'uses custom brand name in signature' do
        expect(mail.body).to match('The Custom Support Team')
        expect(mail.body).not_to match('The Chatwoot Team')
      end
    end
  end

  describe 'AccountComplianceMailer#account_deleted' do
    let(:account) { create(:account) }
    let(:mail) do
      AccountComplianceMailer.account_deleted(
        account,
        {
          account_name: 'Test Account',
          instance_url: 'https://example.com',
          account_id: account.id,
          marked_for_deletion_at: '2024-12-30',
          deleted_at: '2024-12-31',
          deletion_reason: 'User request',
          deleted_user_count: 0,
          soft_deleted_users: []
        }
      )
    end

    context 'with custom brand name' do
      before do
        allow(GlobalConfig).to receive(:get).with('BRAND_NAME', 'INSTALLATION_NAME').and_return({
          'BRAND_NAME' => 'Custom Support',
          'INSTALLATION_NAME' => 'Installation Name'
        })
      end

      it 'uses custom brand name in instance references' do
        expect(mail.body).to match('your Custom Support instance')
        expect(mail.body).not_to match('your Chatwoot instance')
      end

      it 'uses custom brand name in installation header' do
        expect(mail.body).to match('Custom Support Installation:')
        expect(mail.body).not_to match('Chatwoot Installation:')
      end

      it 'uses custom brand name in signature' do
        expect(mail.body).to match('Custom Support System')
        expect(mail.body).not_to match('Chatwoot System')
      end
    end
  end
end