require 'rails_helper'

RSpec.describe Captain::Llm::ContactAttributesService do
  let(:contact) { create(:contact) }
  let(:conversation) { create(:conversation, contact: contact) }
  let(:assistant) { double('Assistant') }
  let(:service) { described_class.new(assistant, conversation) }
  let(:llm_service) { instance_double(Captain::LlmService) }

  before do
    allow(Captain::LlmService).to receive(:new).and_return(llm_service)
  end

  describe '#generate_and_update_attributes' do
    it 'extracts attributes from the conversation' do
      expected_attributes = [{ 'attribute' => 'email', 'value' => 'test@example.com' }]

      allow(llm_service).to receive(:call).and_return({ output: { 'attributes' => expected_attributes }.to_json })

      result = service.generate_and_update_attributes
      expect(result).to eq(expected_attributes)
    end

    it 'returns empty array on error' do
      allow(llm_service).to receive(:call).and_raise(StandardError.new('API Error'))

      result = service.generate_and_update_attributes
      expect(result).to eq([])
    end
  end
end
