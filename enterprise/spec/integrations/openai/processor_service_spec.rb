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
  let!(:conversation) { create(:conversation, account: account) }
  let!(:customer_message) { create(:message, account: account, conversation: conversation, message_type: :incoming, content: 'hello agent') }
  let!(:agent_message) { create(:message, account: account, conversation: conversation, message_type: :outgoing, content: 'hello customer') }

  describe '#perform' do
    context 'when event name is label_suggestion with labels' do
      let(:event) { { 'name' => 'label_suggestion', 'data' => { 'conversation_display_id' => conversation.display_id } } }
      let(:label1) { create(:label, account: account) }
      let(:label2) { create(:label, account: account) }
      let(:label_suggestion_payload) do
        labels = "#{label1.title}, #{label2.title}"
        messages =
          "Customer #{customer_message.sender.name} : #{customer_message.content}\nAgent #{agent_message.sender.name} : #{agent_message.content}"

        "Messages:\n#{messages}\n\nLabels:\n#{labels}"
      end

      it 'returns the label suggestions' do
        request_body = {
          'model' => 'gpt-3.5-turbo',
          'messages' => [
            {
              role: 'system',
              content: 'Your role is as an assistant to a customer support agent. You will be provided with ' \
                       'a transcript of a conversation between a customer and the support agent, along with a list of potential labels. ' \
                       'Your task is to analyze the conversation and select the two labels from the given list that most accurately ' \
                       'represent the themes or issues discussed. Ensure you preserve the exact casing of the labels as they are provided ' \
                       'in the list. Do not create new labels; only choose from those provided. Once you have made your selections, ' \
                       'please provide your response as a comma-separated list of the provided labels. Remember, your response should only contain ' \
                       'the labels you\'ve selected, in their original casing, and nothing else. '
            },
            { role: 'user', content: label_suggestion_payload }
          ]
        }.to_json

        stub_request(:post, 'https://api.openai.com/v1/chat/completions')
          .with(body: request_body, headers: expected_headers)
          .to_return(status: 200, body: openai_response, headers: {})

        result = subject.perform
        expect(result).to eq('This is a reply from openai.')
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
  end
end
