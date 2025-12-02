require 'rails_helper'

RSpec.describe Captain::Llm::ConversationFaqService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:conversation) { create(:conversation, first_reply_created_at: Time.zone.now) }
  let(:service) { described_class.new(captain_assistant, conversation) }
  let(:llm_service) { instance_double(Captain::LlmService) }
  let(:embedding_service) { instance_double(Captain::Llm::EmbeddingService) }

  before do
    allow(Captain::LlmService).to receive(:new).and_return(llm_service)
    allow(Captain::Llm::EmbeddingService).to receive(:new).and_return(embedding_service)
  end

  describe '#generate_and_deduplicate' do
    let(:sample_faqs) do
      [
        { 'question' => 'What is the purpose?', 'answer' => 'To help users.' },
        { 'question' => 'How does it work?', 'answer' => 'Through AI.' }
      ]
    end

    let(:llm_response) do
      { output: { 'faqs' => sample_faqs }.to_json }
    end

    context 'when successful' do
      before do
        allow(llm_service).to receive(:call).and_return(llm_response)
        allow(embedding_service).to receive(:generate).and_return([0.1, 0.2, 0.3])
        allow(captain_assistant.responses).to receive(:nearest_neighbors).and_return([])
      end

      it 'creates new FAQs' do
        expect do
          service.generate_and_deduplicate
        end.to change(captain_assistant.responses, :count).by(2)
      end

      it 'saves the correct FAQ content' do
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
        allow(llm_service).to receive(:call).and_return(llm_response)
        allow(embedding_service).to receive(:generate).and_return([0.1, 0.2, 0.3])
        allow(captain_assistant.responses).to receive(:nearest_neighbors).and_return([similar_neighbor])
      end

      it 'filters out duplicate FAQs' do
        expect do
          service.generate_and_deduplicate
        end.not_to change(captain_assistant.responses, :count)
      end
    end

    context 'when LLM call fails' do
      before do
        allow(llm_service).to receive(:call).and_raise(StandardError.new('API Error'))
      end

      it 'handles the error and returns empty array' do
        expect(Rails.logger).to receive(:error).with('ConversationFaqService Error: API Error')
        expect(service.generate_and_deduplicate).to eq([])
      end
    end
  end
end
