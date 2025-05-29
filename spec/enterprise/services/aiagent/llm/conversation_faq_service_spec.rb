require 'rails_helper'

RSpec.describe Aiagent::Llm::ConversationFaqService do
  let(:aiagent_topic) { create(:aiagent_topic) }
  let(:conversation) { create(:conversation, first_reply_created_at: Time.zone.now) }
  let(:service) { described_class.new(aiagent_topic, conversation) }
  let(:client) { instance_double(OpenAI::Client) }
  let(:embedding_service) { instance_double(Aiagent::Llm::EmbeddingService) }

  before do
    create(:installation_config) { create(:installation_config, name: 'AIAGENT_OPEN_AI_API_KEY', value: 'test-key') }
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(Aiagent::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
  end

  describe '#generate_and_deduplicate' do
    let(:sample_faqs) do
      [
        { 'question' => 'What is the purpose?', 'answer' => 'To help users.' },
        { 'question' => 'How does it work?', 'answer' => 'Through AI.' }
      ]
    end

    let(:openai_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => { faqs: sample_faqs }.to_json
            }
          }
        ]
      }
    end

    context 'when successful' do
      before do
        allow(client).to receive(:chat).and_return(openai_response)
        allow(embedding_service).to receive(:get_embedding).and_return([0.1, 0.2, 0.3])
        allow(aiagent_topic.responses).to receive(:nearest_neighbors).and_return([])
      end

      it 'creates new FAQs' do
        expect do
          service.generate_and_deduplicate
        end.to change(aiagent_topic.responses, :count).by(2)
      end

      it 'saves the correct FAQ content' do
        service.generate_and_deduplicate
        expect(
          aiagent_topic.responses.pluck(:question, :answer, :status, :documentable_id)
        ).to contain_exactly(
          ['What is the purpose?', 'To help users.', 'pending', conversation.id],
          ['How does it work?', 'Through AI.', 'pending', conversation.id]
        )
      end
    end

    context 'without human interaction' do
      let(:conversation) { create(:conversation) }

      it 'returns an empty array without generating FAQs' do
        expect(service.generate_and_deduplicate).to eq([])
      end
    end

    context 'when finding duplicates' do
      let(:existing_response) do
        create(:aiagent_topic_response, topic: aiagent_topic, question: 'Similar question', answer: 'Similar answer')
      end
      let(:similar_neighbor) do
        # Using OpenStruct here to mock as the Aiagent:TopicResponse does not implement
        # neighbor_distance as a method or attribute rather it is returned directly
        # from SQL query in neighbor gem
        OpenStruct.new(
          id: 1,
          question: existing_response.question,
          answer: existing_response.answer,
          neighbor_distance: 0.1
        )
      end

      before do
        allow(client).to receive(:chat).and_return(openai_response)
        allow(embedding_service).to receive(:get_embedding).and_return([0.1, 0.2, 0.3])
        allow(aiagent_topic.responses).to receive(:nearest_neighbors).and_return([similar_neighbor])
      end

      it 'filters out duplicate FAQs' do
        expect do
          service.generate_and_deduplicate
        end.not_to change(aiagent_topic.responses, :count)
      end
    end

    context 'when OpenAI API fails' do
      before do
        allow(client).to receive(:chat).and_raise(OpenAI::Error.new('API Error'))
      end

      it 'handles the error and returns empty array' do
        expect(Rails.logger).to receive(:error).with('OpenAI API Error: API Error')
        expect(service.generate_and_deduplicate).to eq([])
      end
    end

    context 'when JSON parsing fails' do
      let(:invalid_response) do
        {
          'choices' => [
            {
              'message' => {
                'content' => 'invalid json'
              }
            }
          ]
        }
      end

      before do
        allow(client).to receive(:chat).and_return(invalid_response)
      end

      it 'handles JSON parsing errors' do
        expect(Rails.logger).to receive(:error).with(/Error in parsing GPT processed response:/)
        expect(service.generate_and_deduplicate).to eq([])
      end
    end
  end

  describe '#chat_parameters' do
    it 'includes correct model and response format' do
      params = service.send(:chat_parameters)
      expect(params[:model]).to eq('gpt-4o-mini')
      expect(params[:response_format]).to eq({ type: 'json_object' })
    end

    it 'includes system prompt and conversation content' do
      allow(Aiagent::Llm::SystemPromptsService).to receive(:conversation_faq_generator).and_return('system prompt')
      params = service.send(:chat_parameters)

      expect(params[:messages]).to include(
        { role: 'system', content: 'system prompt' },
        { role: 'user', content: conversation.to_llm_text }
      )
    end

    context 'when conversation has different language' do
      let(:account) { create(:account, locale: 'fr') }
      let(:conversation) do
        create(:conversation, account: account,
                              first_reply_created_at: Time.zone.now)
      end

      it 'includes system prompt with correct language' do
        allow(Aiagent::Llm::SystemPromptsService).to receive(:conversation_faq_generator)
          .with('french')
          .and_return('system prompt in french')

        params = service.send(:chat_parameters)

        expect(params[:messages]).to include(
          { role: 'system', content: 'system prompt in french' }
        )
      end
    end
  end
end
