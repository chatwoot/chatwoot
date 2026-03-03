require 'rails_helper'

RSpec.describe Captain::Llm::ContactNotesService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:conversation) { create(:conversation) }
  let(:service) { described_class.new(captain_assistant, conversation) }
  let(:mock_chat) { instance_double(RubyLLM::Chat) }
  let(:sample_notes) do
    [
      'Customer prefers email communication.',
      'Follow up on billing query next week.'
    ]
  end
  let(:mock_response) do
    instance_double(RubyLLM::Message, content: { notes: sample_notes }.to_json)
  end

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(RubyLLM).to receive(:chat).and_return(mock_chat)
    allow(mock_chat).to receive(:with_temperature).and_return(mock_chat)
    allow(mock_chat).to receive(:with_params).and_return(mock_chat)
    allow(mock_chat).to receive(:with_instructions).and_return(mock_chat)
    allow(mock_chat).to receive(:ask).and_return(mock_response)
  end

  describe '#generate_and_update_notes' do
    it 'creates contact notes from the LLM response' do
      expect do
        service.generate_and_update_notes
      end.to change(conversation.contact.notes, :count).by(2)
    end

    it 'requests strict JSON schema response format' do
      expect(mock_chat).to receive(:with_params).with(
        response_format: hash_including(
          type: 'json_schema',
          json_schema: hash_including(
            name: 'contact_notes_response',
            strict: true
          )
        )
      ).and_return(mock_chat)

      service.generate_and_update_notes
    end

    context 'when JSON parsing fails' do
      let(:mock_response) { instance_double(RubyLLM::Message, content: 'invalid json') }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'logs error and skips note creation' do
        expect(Rails.logger).to receive(:error).with(/Error in parsing GPT processed response:/)
        expect do
          service.generate_and_update_notes
        end.not_to change(conversation.contact.notes, :count)
      end
    end
  end
end
