require 'rails_helper'
require 'gemini-ai'

RSpec.describe Captain::Llm::Providers::GeminiProvider do
  let(:api_key) { 'test_api_key' }
  let(:provider) { described_class.new(api_key: api_key) }
  let(:client) { double('GeminiClient') }

  before do
    allow(Gemini).to receive(:new).and_return(client)
  end

  describe '#chat' do
    let(:messages) { [{ 'role' => 'user', 'content' => 'Hello' }] }
    let(:model) { 'gpt-4o' }
    let(:gemini_response) do
      {
        'candidates' => [
          {
            'content' => {
              'parts' => [{ 'text' => 'Hello there' }]
            }
          }
        ]
      }
    end

    it 'calls Gemini API with correct parameters' do
      expect(client).to receive(:stream_generate_content).with(
        {
          contents: [{ role: 'user', parts: [{ text: 'Hello' }] }],
          generationConfig: { response_mime_type: 'application/json' }
        },
        model: 'gemini-1.5-pro'
      ).and_return([gemini_response])

      response = provider.chat(messages: messages, model: model)

      expect(response['choices'][0]['message']['content']).to eq('Hello there')
    end

    it 'handles function calls' do
      function_call_response = {
        'candidates' => [
          {
            'content' => {
              'parts' => [
                {
                  'functionCall' => {
                    'name' => 'test_tool',
                    'args' => { 'param' => 'value' }
                  }
                }
              ]
            }
          }
        ]
      }

      expect(client).to receive(:stream_generate_content).and_return([function_call_response])

      response = provider.chat(messages: messages, model: model)

      tool_call = response['choices'][0]['message']['tool_calls'][0]
      expect(tool_call['function']['name']).to eq('test_tool')
      expect(JSON.parse(tool_call['function']['arguments'])).to eq({ 'param' => 'value' })
    end
  end

  describe '#embedding' do
    let(:text) { 'test text' }
    let(:embedding_response) do
      { 'embedding' => { 'values' => [0.1, 0.2, 0.3] } }
    end

    it 'calls Gemini embedding API' do
      expect(client).to receive(:embed_content).with(
        {
          model: 'models/text-embedding-004',
          content: { parts: [{ text: text }] }
        }
      ).and_return(embedding_response)

      response = provider.embedding(text: text, model: 'any')

      expect(response['data'][0]['embedding']).to eq([0.1, 0.2, 0.3])
    end
  end
end
