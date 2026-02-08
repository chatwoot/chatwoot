require 'rails_helper'

RSpec.describe Integrations::Openai::ProcessorService do
  subject { described_class.new(hook: hook, event: event) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :openai, account: account) }
  let(:expected_headers) { { 'Authorization' => "Bearer #{hook.settings['api_key']}" } }
  let(:openai_response) do
    {
      'choices' => [
        {
          'message' => {
            'content' => 'This is a reply from openai.'
          }
        }
      ]
    }.to_json
  end

  let(:conversation) { create(:conversation, account: account) }

  describe '#perform' do
    context 'when event name is label_suggestion with labels with < 3 messages' do
      let(:event) { { 'name' => 'label_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

      it 'returns nil' do
        create(:label, account: account)
        create(:label, account: account)

        expect(subject.perform).to be_nil
      end
    end

    context 'when event name is label_suggestion with labels with >3 messages' do
      let(:event) { { 'name' => 'label_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

      before do
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent')
        create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'hello customer')
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent 2')
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent 3')
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent 4')

        create(:label, account: account)
        create(:label, account: account)

        hook.settings['label_suggestion'] = 'true'
      end

      it 'returns the label suggestions' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: anything, headers: expected_headers)
          .to_return(status: 200, body: openai_response, headers: {})

        result = subject.perform
        expect(result).to eq({ :message => 'This is a reply from openai.' })
      end

      it 'returns empty string if openai response is blank' do
        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: anything, headers: expected_headers)
          .to_return(status: 200, body: '{}', headers: {})

        result = subject.perform
        expect(result).to eq({ :message => '' })
      end
    end

    context 'when event name is label_suggestion with no labels' do
      let(:event) { { 'name' => 'label_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

      it 'returns nil' do
        result = subject.perform
        expect(result).to be_nil
      end
    end

    context 'when event name is not one that can be processed' do
      let(:event) { { 'name' => 'unknown', 'data' => {} } }

      it 'returns nil' do
        expect(subject.perform).to be_nil
      end
    end

    context 'when hook is not enabled' do
      let(:event) { { 'name' => 'label_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }

      before do
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent')
        create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'hello customer')
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent 2')
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent 3')
        create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent 4')

        create(:label, account: account)
        create(:label, account: account)

        hook.settings['label_suggestion'] = nil
      end

      it 'returns nil' do
        expect(subject.perform).to be_nil
      end
    end
  end
end
