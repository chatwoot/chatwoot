require 'rails_helper'

RSpec.describe Captain::Llm::ConversationFaqService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:conversation) { create(:conversation, first_reply_created_at: Time.zone.now) }
  let(:service) { described_class.new(captain_assistant, conversation) }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:sample_faqs) do
    [
      { 'question' => 'What is the purpose?', 'answer' => 'To help users.' },
      { 'question' => 'How does it work?', 'answer' => 'Through AI.' }
    ]
  end
  let(:mock_response) do
    instance_double(RubyLLM::Message, content: { faqs: sample_faqs }.to_json)
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
    allow(mock_chat).to receive(:with_params).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#generate_and_deduplicate' do
    context 'when successful' do
      before do
        allow(embedding_service).to receive(:get_embedding).and_return([0.1, 0.2, 0.3])
        allow(captain_assistant.responses).to receive(:nearest_neighbors).and_return([])
      end

      it 'creates new FAQs for valid conversation content' do
        expect do
          service.generate_and_deduplicate
        end.to change(captain_assistant.responses, :count).by(2)
      end

      it 'saves FAQs with pending status linked to conversation' do
        service.generate_and_deduplicate
        expect(
          captain_assistant.responses.pluck(:question, :answer, :status, :documentable_id)
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

      it 'does not call the LLM API' do
        expect(RubyLLM).not_to receive(:chat)
        service.generate_and_deduplicate
      end
    end

    context 'when finding duplicates' do
      let(:existing_response) do
        create(:captain_assistant_response, assistant: captain_assistant, question: 'Similar question', answer: 'Similar answer')
      end
      let(:similar_neighbor) do
        OpenStruct.new(
          id: 1,
          question: existing_response.question,
          answer: existing_response.answer,
          neighbor_distance: 0.1
        )
      end

      before do
        allow(embedding_service).to receive(:get_embedding).and_return([0.1, 0.2, 0.3])
        allow(captain_assistant.responses).to receive(:nearest_neighbors).and_return([similar_neighbor])
      end

      it 'filters out duplicate FAQs based on embedding similarity' do
        expect do
          service.generate_and_deduplicate
        end.not_to change(captain_assistant.responses, :count)
      end
    end

    context 'when LLM API fails' do
      before do
        allow(mock_chat).to receive(:ask).and_raise(RubyLLM::Error.new(nil, 'API Error'))
        allow(Rails.logger).to receive(:error)
      end

      it 'returns empty array and logs the error' do
        expect(Rails.logger).to receive(:error).with('LLM API Error: API Error')
        expect(service.generate_and_deduplicate).to eq([])
      end
    end

    context 'when JSON parsing fails' do
      let(:invalid_response) do
        instance_double(RubyLLM::Message, content: 'invalid json')
      end

      before do
        allow(mock_chat).to receive(:ask).and_return(invalid_response)
      end

      it 'handles JSON parsing errors gracefully' do
        expect(Rails.logger).to receive(:error).with(/Error in parsing GPT processed response:/)
        expect(service.generate_and_deduplicate).to eq([])
      end
    end

    context 'when response content is nil' do
      let(:nil_response) do
        instance_double(RubyLLM::Message, content: nil)
      end

      before do
        allow(mock_chat).to receive(:ask).and_return(nil_response)
      end

      it 'returns empty array' do
        expect(service.generate_and_deduplicate).to eq([])
      end
    end
  end

  describe 'language handling' do
    context 'when conversation has different language' do
      let(:account) { create(:account, locale: 'fr') }
      let(:conversation) do
        create(:conversation, account: account, first_reply_created_at: Time.zone.now)
      end

      before do
        allow(embedding_service).to receive(:get_embedding).and_return([0.1, 0.2, 0.3])
        allow(captain_assistant.responses).to receive(:nearest_neighbors).and_return([])
      end

      it 'uses account language for system prompt' do
        expect(Captain::Llm::SystemPromptsService).to receive(:conversation_faq_generator)
          .with('french')
          .at_least(:once)
          .and_call_original

        service.generate_and_deduplicate
      end
    end
  end
end
