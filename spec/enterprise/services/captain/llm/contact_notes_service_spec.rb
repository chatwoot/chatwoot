require 'rails_helper'

RSpec.describe Captain::Llm::ContactNotesService do
  let(:captain_assistant) { create(:captain_assistant) }
  let(:account) { create(:account, locale: 'en') }
  let(:conversation) { create(:conversation, account: account) }
  let(:contact) { conversation.contact }
  let(:service) { described_class.new(captain_assistant, conversation) }
  let(:client) { instance_double(OpenAI::Client) }
  let(:system_prompt) { 'Test system prompt' }

  before do
    create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key')
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(Captain::Llm::SystemPromptsService).to receive(:notes_generator)
      .with(account.locale_english_name).and_return(system_prompt)
  end

  describe '#generate_and_update_notes' do
    let(:openai_response) do
      {
        'choices' => [
          {
            'message' => {
              'content' => {
                notes: [
                  'Customer reported an issue with login',
                  'Follow up needed on billing concerns'
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

      it 'creates notes for the contact' do
        expect { service.generate_and_update_notes }.to change(contact.notes, :count).by(2)
      end

      it 'creates notes with correct content' do
        service.generate_and_update_notes
        expect(contact.notes.pluck(:content)).to contain_exactly('Customer reported an issue with login', 'Follow up needed on billing concerns')
      end

      it 'includes conversation and contact context in chat parameters' do
        service.generate_and_update_notes
        expect(client).to have_received(:chat) do |params|
          messages = params[:parameters][:messages]
          content = messages.find { |m| m[:role] == 'user' }[:content]
          expect(content).to include('#Contact')
          expect(content).to include('#Conversation')
        end
      end

      it 'includes system message in chat parameters' do
        service.generate_and_update_notes
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
        expect { service.generate_and_update_notes }.not_to change(contact.notes, :count)
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
        expect { service.generate_and_update_notes }.not_to change(contact.notes, :count)
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
        expect { service.generate_and_update_notes }.not_to change(contact.notes, :count)
      end
    end
  end

  describe '#chat_parameters' do
    before do
      allow(client).to receive(:chat).and_return({
                                                   'choices' => [
                                                     {
                                                       'message' => {
                                                         'content' => { notes: [] }.to_json
                                                       }
                                                     }
                                                   ]
                                                 })
    end

    it 'includes correct model and response format' do
      service.generate_and_update_notes
      expect(client).to have_received(:chat) do |params|
        parameters = params[:parameters]
        expect(parameters[:model]).to eq('gpt-4o-mini')
        expect(parameters[:response_format]).to eq({ type: 'json_object' })
      end
    end
  end
end
