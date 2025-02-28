require 'rails_helper'

RSpec.describe AutomationRules::TimerFilterService do
  let(:account) { create(:account) }
  let(:conversation) { create(:conversation, account: account, created_at: 2.hours.ago) }

  let(:query_hash) do
    {
      'attribute_key' => query_key,
      'values' => [query_value.to_s],
      'query_operator' => query_operator
    }
  end
  let(:query_string) { described_class.new(conversation, query_hash).query_string }

  describe '#query_string' do
    context 'when attribute_key is contact_wait_time' do
      let(:query_key) { 'contact_wait_time' }
      let(:query_value) { 10 }
      let(:query_operator) { 'and' }

      context 'when contact wait more than 10 minutes, AND operator' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :incoming)
        end

        it 'returns TRUE AND' do
          expect(query_string).to eq(' TRUE and ')
        end
      end

      context 'when contact wait more than 10 minutes, OR operator' do
        let(:query_operator) { 'or' }

        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :incoming)
        end

        it 'returns TRUE OR' do
          expect(query_string).to eq(' TRUE or ')
        end
      end

      context 'when contact wait less than 10 minutes, AND operator' do
        before do
          create(:message, conversation: conversation, created_at: 5.minutes.ago, message_type: :incoming)
        end

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when contact wait less than 10 minutes, OR operator' do
        let(:query_operator) { 'or' }

        before do
          create(:message, conversation: conversation, created_at: 5.minutes.ago, message_type: :incoming)
        end

        it 'returns FALSE OR' do
          expect(query_string).to eq(' FALSE or ')
        end
      end

      context 'when contact wait time is 0' do
        let(:query_value) { 0 }

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when contact wait time is negative' do
        let(:query_value) { -1 }

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when contact wait time more than 10 minutes and have reply from agent' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :incoming)
          create(:message, conversation: conversation, created_at: 11.minutes.ago, message_type: :outgoing)
        end

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when contact wait time more than 10 minutes and have reply from bot' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :incoming)
          create(:message, conversation: conversation, created_at: 11.minutes.ago, message_type: :outgoing)
        end

        it 'returns TRUE AND' do
          conversation.messages.outgoing.update(sender_type: nil, sender_id: nil) # make all messages bot messages
          expect(query_string).to eq(' TRUE and ')
        end
      end
    end

    context 'when attribute_key is agent_wait_time' do
      let(:query_key) { 'agent_wait_time' }
      let(:query_value) { 10 }
      let(:query_operator) { 'and' }

      context 'when agent wait more than 10 minutes, AND operator' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :outgoing)
        end

        it 'returns TRUE AND' do
          expect(query_string).to eq(' TRUE and ')
        end
      end

      context 'when agent wait more than 10 minutes, OR operator' do
        let(:query_operator) { 'or' }

        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :outgoing)
        end

        it 'returns TRUE OR' do
          expect(query_string).to eq(' TRUE or ')
        end
      end

      context 'when agent wait less than 10 minutes, AND operator' do
        before do
          create(:message, conversation: conversation, created_at: 5.minutes.ago, message_type: :outgoing)
        end

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when agent wait less than 10 minutes, OR operator' do
        let(:query_operator) { 'or' }

        before do
          create(:message, conversation: conversation, created_at: 5.minutes.ago, message_type: :outgoing)
        end

        it 'returns FALSE OR' do
          expect(query_string).to eq(' FALSE or ')
        end
      end

      context 'when agent wait time is 0' do
        let(:query_value) { 0 }

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when agent wait time is negative' do
        let(:query_value) { -1 }

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when agent wait time more than 10 minutes and have reply from contact' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :outgoing)
          create(:message, conversation: conversation, created_at: 11.minutes.ago, message_type: :incoming)
        end

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when agent wait time more than 10 minutes and have reply from bot' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :outgoing)
          create(:message, conversation: conversation, created_at: 11.minutes.ago, message_type: :incoming)
        end

        it 'returns TRUE AND' do
          conversation.messages.incoming.update(sender_type: nil, sender_id: nil) # make all messages bot messages
          expect(query_string).to eq(' TRUE and ')
        end
      end

      context 'when agent wait time less than 10 minutes and have reply from contact' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :incoming)
          create(:message, conversation: conversation, created_at: 9.minutes.ago, message_type: :outgoing)
          create(:message, conversation: conversation, created_at: 5.minutes.ago, message_type: :incoming)
        end

        it 'returns FALSE AND' do
          expect(query_string).to eq(' FALSE and ')
        end
      end

      context 'when agent wait time less than 10 minutes and have reply from bot' do
        before do
          create(:message, conversation: conversation, created_at: 15.minutes.ago, message_type: :incoming)
          create(:message, conversation: conversation, created_at: 9.minutes.ago, message_type: :outgoing)
          create(:message, conversation: conversation, created_at: 5.minutes.ago, message_type: :incoming)
        end

        it 'returns FALSE AND' do
          conversation.messages.outgoing.update(sender_type: nil, sender_id: nil) # make all messages bot messages
          expect(query_string).to eq(' FALSE and ')
        end
      end
    end
  end
end
