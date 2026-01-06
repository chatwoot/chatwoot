require 'rails_helper'

RSpec.describe Email::ReplyToBuilder do
  let(:account) { create(:account, domain: 'mail.example.com', support_email: 'support@example.com') }
  let(:agent) { create(:user, account: account) }
  let(:conversation) { create(:conversation, account: account) }
  let(:current_message) { create(:message, conversation: conversation, sender: agent, message_type: :outgoing) }
  let(:inbox) { create(:inbox, account: account) }

  describe '#build' do
    context 'when inbox is an email channel' do
      let(:channel) { create(:channel_email, email: 'care@example.com', account: account) }
      let(:inbox) { create(:inbox, channel: channel, account: account) }

      it 'returns the channel email with sender name formatting' do
        builder = described_class.new(inbox: inbox, message: current_message)
        result = builder.build

        expect(result).to include('care@example.com')
      end

      context 'with friendly inbox' do
        let(:inbox) do
          create(:inbox, channel: channel, account: account, greeting_enabled: true, greeting_message: 'Hello', sender_name_type: :friendly)
        end

        it 'returns friendly formatted sender name' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include(agent.available_name)
          expect(result).to include('care@example.com')
        end
      end

      context 'with professional inbox' do
        let(:inbox) { create(:inbox, channel: channel, account: account, sender_name_type: :professional) }

        it 'returns professional formatted sender name' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('care@example.com')
        end
      end
    end

    context 'when inbox is not an email channel' do
      let(:channel) { create(:channel_api, account: account) }
      let(:inbox) { create(:inbox, channel: channel, account: account) }

      context 'with inbound email enabled' do
        before do
          account.enable_features('inbound_emails')
          account.update!(domain: 'mail.example.com', support_email: 'support@example.com')
        end

        it 'returns reply email with conversation uuid' do
          builder = described_class.new(inbox: inbox,   message: current_message)
          result = builder.build

          expect(result).to include("reply+#{conversation.uuid}@mail.example.com")
        end
      end

      context 'when support_email has display name format and inbound emails are disabled' do
        before do
          account.disable_features('inbound_emails')
          account.update!(support_email: 'Support <support@example.com>')
        end

        it 'returns account support email with display name' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include("#{inbox.name} <support@example.com>")
        end
      end

      context 'when feature is disabled' do
        before do
          account.disable_features('inbound_emails')
        end

        it 'returns account support email' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('support@example.com')
        end
      end

      context 'when inbound email domain is missing' do
        before do
          account.enable_features('inbound_emails')
          account.update!(domain: nil)
        end

        it 'returns account support email' do
          builder = described_class.new(inbox: inbox, message: current_message)
          result = builder.build

          expect(result).to include('support@example.com')
        end
      end
    end
  end
end
