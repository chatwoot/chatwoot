require 'rails_helper'

describe Integrations::Slack::SlackMessageHelper do
  describe '#extract_conversation_id' do
    let(:slack_message_helper) { Object.new.extend(described_class) }

    context 'when a valid conversation URL is provided' do
      let(:valid_url) { '/conversations/12345' }

      it 'returns the extracted conversation ID as a string' do
        conversation_id = slack_message_helper.extract_conversation_id(valid_url)
        expect(conversation_id).to eq('12345')
      end
    end

    context 'when a valid label conversation URL is provided' do
      let(:valid_url) { 'label/premium/conversations/34342' }

      it 'returns the extracted conversation ID as a string' do
        conversation_id = slack_message_helper.extract_conversation_id(valid_url)
        expect(conversation_id).to eq('34342')
      end
    end

    context 'when a valid team conversation URL is provided' do
      let(:valid_url) { 'team/2/conversations/8676' }

      it 'returns the extracted conversation ID as a string' do
        conversation_id = slack_message_helper.extract_conversation_id(valid_url)
        expect(conversation_id).to eq('8676')
      end
    end

    context 'when an invalid URL is provided' do
      let(:invalid_url) { '/invalid/url' }

      it 'returns nil' do
        conversation_id = slack_message_helper.extract_conversation_id(invalid_url)
        expect(conversation_id).to be_nil
      end
    end

    context 'when a non-matching URL is provided' do
      let(:non_matching_url) { '/conversations/' }

      it 'returns nil' do
        conversation_id = slack_message_helper.extract_conversation_id(non_matching_url)
        expect(conversation_id).to be_nil
      end
    end
  end
end
