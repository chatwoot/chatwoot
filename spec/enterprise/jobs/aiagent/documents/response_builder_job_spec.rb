require 'rails_helper'

RSpec.describe Aiagent::Documents::ResponseBuilderJob, type: :job do
  let(:topic) { create(:aiagent_topic) }
  let(:document) { create(:aiagent_document, topic: topic) }
  let(:faq_generator) { instance_double(Aiagent::Llm::FaqGeneratorService) }
  let(:faqs) do
    [
      { 'question' => 'What is Ruby?', 'answer' => 'A programming language' },
      { 'question' => 'What is Rails?', 'answer' => 'A web framework' }
    ]
  end

  before do
    allow(Aiagent::Llm::FaqGeneratorService).to receive(:new)
      .with(document.content)
      .and_return(faq_generator)
    allow(faq_generator).to receive(:generate).and_return(faqs)
  end

  describe '#perform' do
    context 'when processing a document' do
      it 'deletes previous responses' do
        existing_response = create(:aiagent_topic_response, documentable: document)

        described_class.new.perform(document)

        expect { existing_response.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'creates new responses for each FAQ' do
        expect do
          described_class.new.perform(document)
        end.to change(Aiagent::TopicResponse, :count).by(2)

        responses = document.responses.reload
        expect(responses.count).to eq(2)

        first_response = responses.first
        expect(first_response.question).to eq('What is Ruby?')
        expect(first_response.answer).to eq('A programming language')
        expect(first_response.topic).to eq(topic)
        expect(first_response.documentable).to eq(document)
      end
    end
  end
end
