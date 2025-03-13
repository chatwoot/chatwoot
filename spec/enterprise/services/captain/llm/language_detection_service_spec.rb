require 'rails_helper'

RSpec.describe Captain::Llm::LanguageDetectionService do
  let(:service) { described_class.new }
  let(:english_text) { 'Hello, how are you today? I hope you are doing well.' }
  let(:spanish_text) { 'Hola, ¿cómo estás hoy? Espero que estés bien.' }
  let(:french_text) { 'Bonjour, comment allez-vous aujourd\'hui? J\'espère que vous allez bien.' }
  let(:empty_text) { '' }

  before do
    create(:installation_config) { create(:installation_config, name: 'CAPTAIN_OPEN_AI_API_KEY', value: 'test-key') }

    client = instance_double(OpenAI::Client)
    allow(OpenAI::Client).to receive(:new).and_return(client)
    allow(client).to receive(:chat).and_return({ 'choices' => [{ 'message' => { 'content' => nil } }] })
    allow(client).to receive(:chat).with(
      parameters: hash_including(messages: array_including({ role: 'user', content: english_text }))
    ).and_return({ 'choices' => [{ 'message' => { 'content' => '{"language_code": "en"}' } }] })
    allow(client).to receive(:chat).with(
      parameters: hash_including(messages: array_including({ role: 'user', content: spanish_text }))
    ).and_return({ 'choices' => [{ 'message' => { 'content' => '{"language_code": "es"}' } }] })
    allow(client).to receive(:chat).with(
      parameters: hash_including(messages: array_including({ role: 'user', content: french_text }))
    ).and_return({ 'choices' => [{ 'message' => { 'content' => '{"language_code": "fr"}' } }] })
    allow(client).to receive(:chat)
      .with(parameters: hash_including(messages: array_including({ role: 'user', content: 'text that will return bad response' })))
      .and_return({ 'choices' => [{ 'message' => { 'content' => 'en' } }] })
    allow(client).to receive(:chat)
      .with(parameters: hash_including(messages: array_including({ role: 'user', content: 'text that will throw an error' })))
      .and_raise(StandardError.new('Bad Request'))
  end

  describe '#detect' do
    context 'when text is empty' do
      it 'returns nil' do
        expect(service.detect(empty_text)).to be_nil
      end
    end

    context 'when text is in English' do
      it 'returns "en"' do
        expect(service.detect(english_text)).to eq('en')
      end
    end

    context 'when text is in Spanish' do
      it 'returns "es"' do
        expect(service.detect(spanish_text)).to eq('es')
      end
    end

    context 'when text is in French' do
      it 'returns "fr"' do
        expect(service.detect(french_text)).to eq('fr')
      end
    end

    context 'when API call returns a bad response' do
      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Error parsing response/)
        expect(service.detect('text that will return bad response')).to be_nil
      end
    end

    context 'when API call fails' do
      it 'logs the error and returns nil' do
        expect(Rails.logger).to receive(:error).with(/Error detecting language/)
        expect(service.detect('text that will throw an error')).to be_nil
      end
    end
  end
end
