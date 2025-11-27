require 'rails_helper'

RSpec.describe Integrations::Openai::ProcessorService do
  subject { described_class.new(hook: hook, event: event) }

  let(:account) { create(:account) }
  let(:hook) { create(:integrations_hook, :openai, account: account) }

  # Mock RubyLLM objects
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:mock_context) { instance_double(RubyLLM::Context) }
  let(:mock_config) { OpenStruct.new }
  let(:mock_response) do
    instance_double(
      RubyLLM::Message,
      content: 'This is a reply from openai.',
      input_tokens: nil,
      output_tokens: nil
    )
  end
  let(:mock_empty_response) do
    instance_double(
      RubyLLM::Message,
      content: '',
      input_tokens: nil,
      output_tokens: nil
    )
  end

  let(:conversation) { create(:conversation, account: account) }

  before do
    allow(RubyLLM).to receive(:context).and_yield(mock_config).and_return(mock_context)
    allow(mock_context).to receive(:chat).and_return(mock_chat)

    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:add_message).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

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
        result = subject.perform
        expect(result).to eq({ message: 'This is a reply from openai.' })
      end

      it 'returns empty string if openai response is blank' do
        allow(mock_chat).to receive(:ask).and_return(mock_empty_response)

        result = subject.perform
        expect(result[:message]).to eq('')
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
