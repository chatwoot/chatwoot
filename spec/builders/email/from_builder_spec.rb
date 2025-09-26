require 'rails_helper'

RSpec.describe Email::FromBuilder do
  let(:account) { create(:account, support_email: 'support@example.com') }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:current_message) { create(:message, conversation: conversation, sender: agent, message_type: :outgoing) }

  describe '#build' do
    context 'when inbox is not an email channel' do
      let(:channel) { create(:channel_api, account: account) }
      let(:inbox) { create(:inbox, channel: channel, account: account) }

      it 'returns account support email with sender name formatting' do
        builder = described_class.new(inbox: inbox, message: current_message)
        result = builder.build

        expect(result).to include('support@example.com')
      end

      context 'with friendly inbox' do
        let(:inbox) { create(:inbox, channel: channel, account: account, sender_name_type: :friendly) }

        it 'returns friendly formatted sender name with support email' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include(agent.available_name)
          expect(result).to include('support@example.com')
        end
      end

      context 'with professional inbox' do
        let(:inbox) { create(:inbox, channel: channel, account: account, sender_name_type: :professional) }

        it 'returns professional formatted sender name with support email' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('support@example.com')
        end
      end
    end

    context 'when inbox is an email channel' do
      let(:channel) { create(:channel_email, email: 'care@example.com', account: account) }
      let(:inbox) { create(:inbox, channel: channel, account: account) }

      context 'with standard IMAP/SMTP configuration' do
        before do
          channel.update!(
            imap_enabled: true,
            smtp_enabled: true,
            imap_address: 'imap.example.com',
            smtp_address: 'smtp.example.com'
          )
        end

        it 'returns channel email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end

      context 'with Google OAuth configuration' do
        before do
          channel.update!(
            provider: 'google',
            imap_enabled: true,
            provider_config: { access_token: 'token', refresh_token: 'refresh' }
          )
        end

        it 'returns channel email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end

      context 'with Microsoft OAuth configuration' do
        before do
          channel.update!(
            provider: 'microsoft',
            imap_enabled: true,
            provider_config: { access_token: 'token', refresh_token: 'refresh' }
          )
        end

        it 'returns channel email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end

      context 'with forwarding and own SMTP configuration' do
        before do
          channel.update!(
            imap_enabled: false,
            smtp_enabled: true,
            smtp_address: 'smtp.example.com'
          )
        end

        it 'returns channel email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end

      context 'with IMAP enabled and Chatwoot SMTP and channel is verified_for_sending' do
        before do
          channel.update!(verified_for_sending: true, imap_enabled: true, smtp_enabled: false)
        end

        it 'returns channel email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end

      context 'with IMAP enabled and Chatwoot SMTP and channel is not verified_for_sending' do
        before do
          channel.update!(verified_for_sending: false, imap_enabled: true, smtp_enabled: false)
        end

        it 'returns account support email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('support@example.com')
        end
      end

      context 'with forwarding and Chatwoot SMTP and channel is verified_for_sending' do
        before do
          channel.update!(verified_for_sending: true, imap_enabled: false, smtp_enabled: false)
        end

        it 'returns channel email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end

      context 'with forwarding and Chatwoot SMTP and channel is not verified_for_sending' do
        before { channel.update!(verified_for_sending: false, imap_enabled: false, smtp_enabled: false) }

        it 'returns account support email with sender name formatting' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('support@example.com')
        end
      end
    end
  end
end
