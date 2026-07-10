require 'rails_helper'

RSpec.describe Llm::ResponsesClient do
  let(:openai_client) { instance_double(OpenAI::Client) }
  let(:client) { described_class.new(api_key: 'test-key', api_base: 'https://api.openai.com/v1', client: openai_client) }

  let(:response_body) do
    {
      'id' => 'resp_123',
      'status' => 'completed',
      'model' => 'gpt-5.6-terra',
      'output' => [
        {
          'type' => 'message',
          'content' => [
            { 'type' => 'output_text', 'text' => 'Hello' }
          ]
        },
        {
          'type' => 'function_call',
          'id' => 'fc_123',
          'call_id' => 'call_123',
          'name' => 'lookup_faq',
          'arguments' => '{"query":"billing"}',
          'status' => 'completed'
        }
      ],
      'usage' => {
        'input_tokens' => 10,
        'output_tokens' => 5,
        'total_tokens' => 15,
        'output_tokens_details' => { 'reasoning_tokens' => 2 }
      }
    }
  end

  before do
    allow(openai_client).to receive(:json_post).and_return(response_body)
  end

  describe '#create' do
    it 'sends a Responses API payload with reasoning effort and store disabled' do
      messages = [
        { role: 'system', content: 'Answer as a support assistant.' },
        { role: 'user', content: 'Hi' }
      ]

      result = client.create(
        model: 'gpt-5.6-terra',
        messages: messages,
        reasoning_effort: 'medium',
        metadata: { feature: 'assistant' }
      )

      expect(openai_client).to have_received(:json_post).with(
        path: '/responses',
        parameters: {
          model: 'gpt-5.6-terra',
          input: [{ role: 'user', content: 'Hi' }],
          store: false,
          text: { format: { type: 'text' } },
          instructions: 'Answer as a support assistant.',
          reasoning: { effort: 'medium' },
          metadata: { feature: 'assistant' }
        }
      )
      expect(result).to include(
        message: 'Hello',
        response_id: 'resp_123',
        model: 'gpt-5.6-terra',
        status: 'completed',
        request_messages: messages
      )
      expect(result[:usage]).to eq(
        'prompt_tokens' => 10,
        'completion_tokens' => 5,
        'total_tokens' => 15,
        'reasoning_tokens' => 2
      )
      expect(result[:function_calls]).to contain_exactly(
        'id' => 'fc_123',
        'call_id' => 'call_123',
        'name' => 'lookup_faq',
        'arguments' => { 'query' => 'billing' },
        'status' => 'completed'
      )
    end

    it 'returns a local error when no conversation messages are present' do
      result = client.create(
        model: 'gpt-5.6-terra',
        messages: [{ role: 'system', content: 'Only instructions' }],
        reasoning_effort: 'low'
      )

      expect(openai_client).not_to have_received(:json_post)
      expect(result).to eq(
        error: 'No conversation messages provided',
        error_code: 400,
        request_messages: [{ role: 'system', content: 'Only instructions' }]
      )
    end
  end

  describe '#build_payload' do
    class TestResponsesSchema
      def to_json_schema
        {
          name: 'captain.response',
          schema: {
            type: 'object',
            properties: {
              response: { type: 'string' }
            },
            required: ['response'],
            additionalProperties: false
          },
          strict: true
        }
      end
    end

    it 'uses Responses text.format for structured outputs' do
      payload = client.build_payload(
        model: 'gpt-5.6-terra',
        messages: [{ role: 'user', content: 'Summarize' }],
        schema: TestResponsesSchema
      )

      expect(payload[:text]).to eq(
        format: {
          type: 'json_schema',
          name: 'captain_response',
          schema: {
            type: 'object',
            properties: {
              response: { type: 'string' }
            },
            required: ['response'],
            additionalProperties: false
          },
          strict: true
        }
      )
    end

    it 'normalizes chat-style function tools to Responses function tools' do
      payload = client.build_payload(
        model: 'gpt-5.6-terra',
        messages: [{ role: 'user', content: 'Find docs' }],
        tools: [
          {
            type: 'function',
            function: {
              name: 'lookup_faq',
              description: 'Search FAQs',
              parameters: {
                type: 'object',
                properties: {
                  query: { type: 'string' }
                },
                required: ['query']
              }
            }
          }
        ]
      )

      expect(payload[:tools]).to eq(
        [
          {
            type: 'function',
            name: 'lookup_faq',
            description: 'Search FAQs',
            parameters: {
              type: 'object',
              properties: {
                query: { type: 'string' }
              },
              required: ['query']
            },
            strict: true
          }
        ]
      )
    end

    it 'normalizes multimodal chat content to Responses input blocks' do
      payload = client.build_payload(
        model: 'gpt-5.6-terra',
        messages: [
          {
            role: 'user',
            content: [
              { type: 'text', text: 'What is in this image?' },
              { type: 'image_url', image_url: { url: 'https://example.com/image.png' } }
            ]
          }
        ]
      )

      expect(payload[:input]).to eq(
        [
          {
            role: 'user',
            content: [
              { type: 'input_text', text: 'What is in this image?' },
              { type: 'input_image', image_url: 'https://example.com/image.png' }
            ]
          }
        ]
      )
    end
  end
end
