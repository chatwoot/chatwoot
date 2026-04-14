require 'rails_helper'

describe MessageFinder do
  subject(:message_finder) { described_class.new(conversation, params) }

  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:contact) { create(:contact, email: nil) }
  let!(:conversation) do
    create(:conversation, account: account, inbox: inbox, assignee: user, contact: contact)
  end

  before do
    create(:message, account: account, inbox: inbox, conversation: conversation)
    create(:message, message_type: 'activity', account: account, inbox: inbox, conversation: conversation)
    create(:message, message_type: 'activity', account: account, inbox: inbox, conversation: conversation)
    # this outgoing message creates 2 additional messages because of the email hook execution service
    create(:message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation)
  end

  describe '#perform' do
    context 'with filter_internal_messages false' do
      let(:params) { { filter_internal_messages: false } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 6
      end
    end

    context 'with filter_internal_messages true' do
      let(:params) { { filter_internal_messages: true } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 4
      end
    end

    context 'with before attribute' do
      let!(:outgoing) { create(:message, message_type: 'outgoing', account: account, inbox: inbox, conversation: conversation) }
      let(:params) { { before: outgoing.id } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 6
      end
    end

    context 'with after attribute' do
      let(:params) { { after: conversation.messages.first.id } }

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 5
        expect(result.first.id).to be conversation.messages.second.id
        expect(result.last.message_type).to eq 'outgoing'
      end
    end

    context 'with after and before attribute' do
      let(:params) do
        {
          after: conversation.messages.first.id,
          before: conversation.messages.last.id
        }
      end

      it 'filter conversations by status' do
        result = message_finder.perform
        expect(result.count).to be 5
        expect(result.last.id).to be conversation.messages[-2].id
      end
    end

    context 'with non-existent before id' do
      let(:params) { { before: 0 } }

      it 'returns no messages' do
        expect(message_finder.perform).to be_empty
      end
    end

    context 'with non-existent after id' do
      let(:params) { { after: 0 } }

      it 'returns no messages' do
        expect(message_finder.perform).to be_empty
      end
    end

    context 'when historical messages have higher IDs but older timestamps' do
      # Simulates WhatsApp history sync: message inserted after live messages (higher ID)
      # but with an old created_at
      let!(:historical_message) do
        create(:message, account: account, inbox: inbox, conversation: conversation,
                         created_at: 1.year.ago)
      end
      let(:earliest_live_message) { conversation.messages.order(:created_at).find { |m| m.created_at > 1.month.ago } }

      context 'with before pointing to earliest live message' do
        let(:params) { { before: earliest_live_message.id } }

        it 'includes historical messages despite having higher IDs' do
          expect(message_finder.perform).to include(historical_message)
        end
      end

      context 'with after pointing to historical message' do
        let(:params) { { after: historical_message.id } }

        it 'returns live messages with newer timestamps' do
          expect(message_finder.perform).to include(earliest_live_message)
        end
      end

      context 'with between range covering live messages' do
        let!(:new_live_message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
        let(:params) { { after: earliest_live_message.id, before: new_live_message.id } }

        it 'excludes historical messages outside the timestamp range' do
          expect(message_finder.perform).not_to include(historical_message)
        end
      end
    end
  end
end
