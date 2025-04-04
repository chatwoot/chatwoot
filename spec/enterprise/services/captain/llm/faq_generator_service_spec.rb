require 'rails_helper'

RSpec.describe Captain::Llm::FaqGeneratorService do
  let(:content) { 'How do I reset my password? Click on forgot password link.' }
  let(:service) { described_class.new(content) }
  let(:client) { instance_double(OpenAI::Client) }
  let(:system_prompt) { 'Test system prompt' }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(Captain::Llm::SystemPromptsService).to receive(:faq_generator).and_return(system_prompt)
  end

  describe '#generate' do
    let(:openai_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => {
                faqs: [
                  {
                    question: 'How do I reset my password?',
                    answer: 'Click on forgot password link.'
                  },
                  {
                    question: 'Where is the forgot password link?',
                    answer: 'The forgot password link is on the login page.'
                  }
                ]
              }.to_json
            }
          }
        ]
      }
    end

    context 'when successful' do
      before do
        allow(client).to receive(:chat).and_return(openai_response)
      end

      it 'generates FAQs from content' do
        faqs = service.generate
        expect(faqs).to contain_exactly(
          {
            'question' => 'How do I reset my password?',
            'answer' => 'Click on forgot password link.'
          },
          {
            'question' => 'Where is the forgot password link?',
            'answer' => 'The forgot password link is on the login page.'
          }
        )
      end

      it 'includes content in chat parameters' do
        service.generate
        expect(client).to have_received(:chat) do |params|
          messages = params[:parameters][:messages]
          user_message = messages.find { |m| m[:role] == 'user' }
          expect(user_message[:content]).to eq(content)
        end
      end

      it 'includes system message in chat parameters' do
        service.generate
        expect(client).to have_received(:chat) do |params|
          messages = params[:parameters][:messages]
          system_message = messages.find { |m| m[:role] == 'system' }
          expect(system_message[:content]).to eq(system_prompt)
        end
      end
    end

    context 'when OpenAI API fails' do
      before do
        allow(client).to receive(:chat).and_raise(OpenAI::Error.new('API Error'))
      end

      it 'logs error and returns empty array' do
        expect(Rails.logger).to receive(:error).with('OpenAI API Error: API Error')
        expect(service.generate).to eq([])
      end
    end

    context 'when response parsing fails' do
      let(:invalid_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => 'Invalid JSON'
              }
            }
          ]
        }
      end

      before do
        allow(client).to receive(:chat).and_return(invalid_response)
      end

      it 'logs error and returns empty array' do
        expect(Rails.logger).to receive(:error).with(/Error in parsing GPT processed response/)
        expect(service.generate).to eq([])
      end
    end

    context 'when response is missing content' do
      let(:empty_response) do
        {
          'choices' => [
            {
              'message' => {}
            }
          ]
        }
      end

      before do
        allow(client).to receive(:chat).and_return(empty_response)
      end

      it 'returns empty array' do
        expect(service.generate).to eq([])
      end
    end
  end

  describe '#chat_parameters' do
    before do
      allow(client).to receive(:chat).and_return({
                                                   'choices' => [
                                                     {
                                                       'message' => {
                                                         'content' => { faqs: [] }.to_json
                                                       }
                                                     }
                                                   ]
                                                 })
    end

    it 'includes correct model and response format' do
      service.generate
      expect(client).to have_received(:chat) do |params|
        parameters = params[:parameters]
        expect(parameters[:model]).to eq('gpt-4o-mini')
        expect(parameters[:response_format]).to eq({ type: 'json_object' })
      end
    end
  end
end
