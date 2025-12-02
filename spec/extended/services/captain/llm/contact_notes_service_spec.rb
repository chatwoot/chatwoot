require 'rails_helper'

RSpec.describe Captain::Llm::ContactNotesService do
  let(:contact) { create(:contact) }
  let(:conversation) { create(:conversation, contact: contact) }
  let(:assistant) { double('Assistant') }
  let(:service) { described_class.new(assistant, conversation) }
  let(:llm_service) { instance_double(Captain::LlmService) }

  before do
    allow(Captain::LlmService).to receive(:new).and_return(llm_service)
  end

  describe '#generate_and_update_notes' do
    it 'creates notes for the contact' do
      expected_notes = ['Note 1', 'Note 2']

      allow(llm_service).to receive(:call).and_return({ output: { 'notes' => expected_notes }.to_json })

      expect do
        service.generate_and_update_notes
      end.to change(contact.notes, :count).by(2)

      expect(contact.notes.pluck(:content)).to include('Note 1', 'Note 2')
    end

    it 'handles errors gracefully' do
      allow(llm_service).to receive(:call).and_raise(StandardError.new('API Error'))

      expect do
        service.generate_and_update_notes
      end.not_to change(contact.notes, :count)
    end
  end
end
