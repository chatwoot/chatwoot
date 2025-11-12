require 'rails_helper'

RSpec.describe Mailbox::ConversationFinder do
  let(:account) { create(:account) }
  let(:email_channel) { create(:channel_email, email: 'test@example.com', account: account) }
  let(:conversation) { create(:conversation, inbox: email_channel.inbox, account: account) }
  let(:mail) { Mail.new }

  describe '#find' do
    context 'when receiver uuid strategy finds conversation' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'reply+12345678-1234-1234-1234-123456789012@example.com'
      end

      it 'returns the conversation' do
        finder = described_class.new(mail)
        expect(finder.find).to eq(conversation)
      end

      it 'logs which strategy succeeded' do
        allow(Rails.logger).to receive(:info)
        finder = described_class.new(mail)
        finder.find

        expect(Rails.logger).to have_received(:info).with('Conversation found via receiver_uuid_strategy strategy')
      end
    end

    context 'when in_reply_to strategy finds conversation' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.in_reply_to = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
      end

      it 'returns the conversation' do
        finder = described_class.new(mail)
        expect(finder.find).to eq(conversation)
      end

      it 'logs which strategy succeeded' do
        allow(Rails.logger).to receive(:info)
        finder = described_class.new(mail)
        finder.find

        expect(Rails.logger).to have_received(:info).with('Conversation found via in_reply_to_strategy strategy')
      end
    end

    context 'when references strategy finds conversation' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')
        mail.to = 'test@example.com'
        mail.references = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
      end

      it 'returns the conversation' do
        finder = described_class.new(mail)
        expect(finder.find).to eq(conversation)
      end

      it 'logs which strategy succeeded' do
        allow(Rails.logger).to receive(:info)
        finder = described_class.new(mail)
        finder.find

        expect(Rails.logger).to have_received(:info).with('Conversation found via references_strategy strategy')
      end
    end

    context 'when no strategy finds conversation' do
      # With NewConversationStrategy in default strategies, this scenario only happens
      # when using custom strategies that exclude NewConversationStrategy
      let(:finding_strategies) do
        [
          Mailbox::ConversationFinderStrategies::ReceiverUuidStrategy,
          Mailbox::ConversationFinderStrategies::InReplyToStrategy,
          Mailbox::ConversationFinderStrategies::ReferencesStrategy
        ]
      end

      it 'returns nil' do
        finder = described_class.new(mail, strategies: finding_strategies)
        expect(finder.find).to be_nil
      end

      it 'logs that no conversation was found' do
        allow(Rails.logger).to receive(:error)
        finder = described_class.new(mail, strategies: finding_strategies)
        finder.find

        expect(Rails.logger).to have_received(:error).with('No conversation found via any strategy (NewConversationStrategy missing?)')
      end
    end

    context 'with custom strategies' do
      let(:custom_strategy_class) do
        Class.new(Mailbox::ConversationFinderStrategies::BaseStrategy) do
          def find
            # Always return nil for testing
            nil
          end
        end
      end

      it 'uses provided strategies instead of defaults' do
        finder = described_class.new(mail, strategies: [custom_strategy_class])
        expect(finder.find).to be_nil
      end
    end

    context 'with strategy execution order' do
      before do
        conversation.update!(uuid: '12345678-1234-1234-1234-123456789012')

        # Set up mail so all strategies could match
        mail.to = 'reply+12345678-1234-1234-1234-123456789012@example.com'
        mail.in_reply_to = 'conversation/12345678-1234-1234-1234-123456789012/messages/123@example.com'
        mail.references = 'conversation/12345678-1234-1234-1234-123456789012/messages/456@example.com'
      end

      it 'returns conversation from first matching strategy' do
        allow(Rails.logger).to receive(:info)
        finder = described_class.new(mail)
        result = finder.find

        expect(result).to eq(conversation)
        # Should only log the first strategy that succeeded (ReceiverUuidStrategy)
        expect(Rails.logger).to have_received(:info).once.with('Conversation found via receiver_uuid_strategy strategy')
      end
    end
  end
end
