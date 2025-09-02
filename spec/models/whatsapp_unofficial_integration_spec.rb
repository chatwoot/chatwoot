# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::Whatsapp, type: :model do
  describe 'Unofficial WhatsApp Integration Detection' do
    let(:account) { create(:account) }
    
    describe 'provider detection' do
      context 'when using official WhatsApp Cloud API' do
        let(:channel) do
          create(:channel_whatsapp, 
                 account: account,
                 provider: 'whatsapp_cloud',
                 provider_config: { 'business_account_id' => 'test123' })
        end

        it 'identifies as official provider' do
          expect(channel.provider).to eq('whatsapp_cloud')
          expect(channel.provider).not_to eq('default')
        end

        it 'should not trigger risk banner' do
          # This would be a frontend test, but we can verify backend logic
          expect(channel.provider).to eq('whatsapp_cloud')
        end
      end

      context 'when using unofficial 360Dialog provider' do
        let(:channel) do
          create(:channel_whatsapp,
                 account: account, 
                 provider: 'default',
                 provider_config: { 'api_key' => 'test_api_key' })
        end

        it 'identifies as unofficial provider' do
          expect(channel.provider).to eq('default')
          expect(channel.provider).not_to eq('whatsapp_cloud')
        end

        it 'should trigger risk banner' do
          # This would be a frontend test, but we can verify backend logic
          expect(channel.provider).not_to eq('whatsapp_cloud')
        end
      end
    end

    describe 'email notifications on provider changes' do
      let(:admin_user) { create(:user) }
      let(:channel) { create(:channel_whatsapp, account: account, provider: 'default') }

      before do
        create(:account_user, account: account, user: admin_user, role: :administrator)
        allow(WhatsappMigrationMailer).to receive(:official_api_confirmation).and_return(double(deliver_later: true))
        allow(WhatsappMigrationMailer).to receive(:unofficial_risk_notification).and_return(double(deliver_later: true))
      end

      context 'when switching from unofficial to official' do
        it 'sends official API confirmation email' do
          expect(WhatsappMigrationMailer).to receive(:official_api_confirmation)
            .with(account, admin_user, channel)
            .and_return(double(deliver_later: true))

          channel.update!(provider: 'whatsapp_cloud')
        end
      end

      context 'when switching from official to unofficial' do
        let(:official_channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud') }

        before do
          create(:account_user, account: account, user: admin_user, role: :administrator)
        end

        it 'sends unofficial risk notification email' do
          expect(WhatsappMigrationMailer).to receive(:unofficial_risk_notification)
            .with(account, admin_user, official_channel)
            .and_return(double(deliver_later: true))

          official_channel.update!(provider: 'default')
        end
      end

      context 'when no provider change occurs' do
        it 'does not send any emails' do
          expect(WhatsappMigrationMailer).not_to receive(:official_api_confirmation)
          expect(WhatsappMigrationMailer).not_to receive(:unofficial_risk_notification)

          channel.update!(phone_number: '+447700900123')
        end
      end
    end

    describe 'WhatsappMigrationNotifiable concern' do
      let(:admin_user) { create(:user) }
      let(:channel) { create(:channel_whatsapp, account: account, provider: 'default') }

      before do
        create(:account_user, account: account, user: admin_user, role: :administrator)
      end

      describe '#provider_changed_to_official?' do
        it 'returns true when changing from default to whatsapp_cloud' do
          channel.provider = 'whatsapp_cloud'
          expect(channel.send(:provider_changed_to_official?)).to be_truthy
        end

        it 'returns false when provider remains the same' do
          expect(channel.send(:provider_changed_to_official?)).to be_falsy
        end
      end

      describe '#provider_changed_to_unofficial?' do
        let(:official_channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud') }

        it 'returns true when changing from whatsapp_cloud to default' do
          official_channel.provider = 'default'
          expect(official_channel.send(:provider_changed_to_unofficial?)).to be_truthy
        end

        it 'returns false when provider remains the same' do
          expect(official_channel.send(:provider_changed_to_unofficial?)).to be_falsy
        end
      end
    end
  end

  describe 'Risk Assessment' do
    let(:account) { create(:account) }

    context 'with multiple WhatsApp channels' do
      let!(:official_channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud') }
      let!(:unofficial_channel1) { create(:channel_whatsapp, account: account, provider: 'default', phone_number: '+447700900001') }
      let!(:unofficial_channel2) { create(:channel_whatsapp, account: account, provider: 'default', phone_number: '+447700900002') }

      it 'identifies all unofficial channels' do
        unofficial_channels = account.channels.joins(:channel_whatsapp)
                                     .where(channel_whatsapp: { provider: 'default' })

        expect(unofficial_channels.count).to eq(2)
        expect(unofficial_channels.pluck('channel_whatsapp.phone_number')).to match_array([
          '+447700900001', '+447700900002'
        ])
      end

      it 'identifies official channels separately' do
        official_channels = account.channels.joins(:channel_whatsapp)
                                   .where(channel_whatsapp: { provider: 'whatsapp_cloud' })

        expect(official_channels.count).to eq(1)
      end
    end

    context 'risk banner visibility logic' do
      it 'should show banner for accounts with unofficial channels' do
        create(:channel_whatsapp, account: account, provider: 'default')
        
        unofficial_channels = account.channels.joins(:channel_whatsapp)
                                     .where.not(channel_whatsapp: { provider: 'whatsapp_cloud' })

        expect(unofficial_channels).not_to be_empty
      end

      it 'should not show banner for accounts with only official channels' do
        create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud')
        
        unofficial_channels = account.channels.joins(:channel_whatsapp)
                                     .where.not(channel_whatsapp: { provider: 'whatsapp_cloud' })

        expect(unofficial_channels).to be_empty
      end
    end
  end

  describe 'Security and Compliance' do
    let(:account) { create(:account) }
    let(:unofficial_channel) { create(:channel_whatsapp, account: account, provider: 'default') }
    let(:official_channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_cloud') }

    it 'validates provider configuration for unofficial channels' do
      unofficial_channel.provider_config = {}
      expect(unofficial_channel).not_to be_valid
      expect(unofficial_channel.errors[:provider_config]).to include('Invalid Credentials')
    end

    it 'validates provider configuration for official channels' do  
      official_channel.provider_config = {}
      expect(official_channel).not_to be_valid
      expect(official_channel.errors[:provider_config]).to include('Invalid Credentials')
    end

    it 'ensures webhook verify token for official channels' do
      channel = build(:channel_whatsapp, account: account, provider: 'whatsapp_cloud')
      channel.provider_config = { 'business_account_id' => 'test123' }
      channel.valid?
      
      expect(channel.provider_config['webhook_verify_token']).not_to be_nil
      expect(channel.provider_config['webhook_verify_token']).to be_a(String)
      expect(channel.provider_config['webhook_verify_token'].length).to eq(32)
    end

    it 'does not require webhook verify token for unofficial channels' do
      channel = build(:channel_whatsapp, account: account, provider: 'default')
      channel.provider_config = { 'api_key' => 'test_key' }
      
      expect(channel.provider_config['webhook_verify_token']).to be_nil
    end
  end

  describe 'Edge Cases' do
    let(:account) { create(:account) }

    context 'when account has no administrators' do
      let(:channel) { create(:channel_whatsapp, account: account, provider: 'default') }

      it 'handles missing administrator gracefully' do
        expect { channel.update!(provider: 'whatsapp_cloud') }.not_to raise_error
      end
    end

    context 'when switching providers multiple times' do
      let(:admin_user) { create(:user) }
      let(:channel) { create(:channel_whatsapp, account: account, provider: 'default') }

      before do
        create(:account_user, account: account, user: admin_user, role: :administrator)
        allow(WhatsappMigrationMailer).to receive(:official_api_confirmation).and_return(double(deliver_later: true))
        allow(WhatsappMigrationMailer).to receive(:unofficial_risk_notification).and_return(double(deliver_later: true))
      end

      it 'sends appropriate emails for each switch' do
        # Switch to official
        expect(WhatsappMigrationMailer).to receive(:official_api_confirmation)
        channel.update!(provider: 'whatsapp_cloud')

        # Switch back to unofficial
        expect(WhatsappMigrationMailer).to receive(:unofficial_risk_notification)  
        channel.update!(provider: 'default')
      end
    end

    context 'banner persistence' do
      it 'banner state should persist until provider changes' do
        unofficial_channel = create(:channel_whatsapp, account: account, provider: 'default')
        
        # Simulate multiple page refreshes - banner should still show
        expect(unofficial_channel.provider).not_to eq('whatsapp_cloud')
        
        # Update other attributes - banner should still show
        unofficial_channel.update!(phone_number: '+447700900999')
        expect(unofficial_channel.provider).not_to eq('whatsapp_cloud')
        
        # Only changing to official should remove banner condition
        unofficial_channel.update!(provider: 'whatsapp_cloud')
        expect(unofficial_channel.provider).to eq('whatsapp_cloud')
      end
    end
  end
end