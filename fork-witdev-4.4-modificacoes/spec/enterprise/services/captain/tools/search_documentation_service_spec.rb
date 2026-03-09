require 'rails_helper'

RSpec.describe Captain::Tools::SearchDocumentationService do
  let(:assistant) { create(:captain_assistant) }
  let(:service) { described_class.new(assistant) }
  let(:question) { 'How to create a new account?' }
  let(:answer) { 'You can create a new account by clicking on the Sign Up button.' }
  let(:external_link) { 'https://example.com/docs/create-account' }

  describe '#name' do
    it 'returns the correct service name' do
      expect(service.name).to eq('search_documentation')
    end
  end

  describe '#description' do
    it 'returns the service description' do
      expect(service.description).to eq('Search and retrieve documentation from knowledge base')
    end
  end

  describe '#parameters' do
    it 'returns the required parameters schema' do
      expected_schema = {
        type: 'object',
        properties: {
          search_query: {
            type: 'string',
            description: 'The search query to look up in the documentation.'
          }
        },
        required: ['search_query']
      }

      expect(service.parameters).to eq(expected_schema)
    end
  end

  describe '#execute' do
    let!(:response) do
      create(
        :captain_assistant_response,
        assistant: assistant,
        question: question,
        answer: answer,
        status: 'approved'
      )
    end

    let(:documentable) { create(:captain_document, external_link: external_link) }

    context 'when matching responses exist' do
      before do
        response.update(documentable: documentable)
        allow(Captain::AssistantResponse).to receive(:search).with(question).and_return([response])
      end

      it 'returns formatted responses for the search query' do
        result = service.execute({ 'search_query' => question })

        expect(result).to include(question)
        expect(result).to include(answer)
        expect(result).to include(external_link)
      end
    end

    context 'when no matching responses exist' do
      before do
        allow(Captain::AssistantResponse).to receive(:search).with(question).and_return([])
      end

      it 'returns an empty string' do
        expect(service.execute({ 'search_query' => question })).to eq('No FAQs found for the given query')
      end
    end
  end
end
