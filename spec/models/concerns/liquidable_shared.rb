require 'rails_helper'

shared_examples_for 'liqudable' do
  context 'when liquid is present in content' do
    let(:contact) { create(:contact, name: 'john', phone_number: '+912883') }
    let(:conversation) { create(:conversation, id: 1, contact: contact) }

    context 'when message is incoming' do
      let(:message) { build(:message, conversation: conversation, message_type: 'incoming') }

      it 'will not process liquid in content' do
        message.content = 'hey {{contact.name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey {{contact.name}} how are you?'
      end
    end

    context 'when message is outgoing' do
      let(:message) { build(:message, conversation: conversation, message_type: 'outgoing') }

      it 'set replaces liquid variables in message' do
        message.content = 'hey {{contact.name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey John how are you?'
      end

      it 'process liquid operators like default value' do
        message.content = 'Can we send you an email at {{ contact.email | default: "default"  }} ?'
        message.save!
        expect(message.content).to eq 'Can we send you an email at default ?'
      end

      it 'return empty string when value is not available' do
        message.content = 'Can we send you an email at {{contact.email}}?'
        message.save!
        expect(message.content).to eq 'Can we send you an email at ?'
      end

      it 'will skip processing broken liquid tags' do
        message.content = 'Can we send you an email at {{contact.email}  {{hi}} ?'
        message.save!
        expect(message.content).to eq 'Can we send you an email at {{contact.email}  {{hi}} ?'
      end

      it 'will not process liquid tags in multiple code blocks' do
        message.content = 'hey {{contact.name}} how are you? ```code: {{contact.name}}``` ``` code: {{contact.name}} ``` test `{{contact.name}}`'
        message.save!
        expect(message.content).to eq 'hey John how are you? ```code: {{contact.name}}``` ``` code: {{contact.name}} ``` test `{{contact.name}}`'
      end

      it 'will not process liquid tags in single ticks' do
        message.content = 'hey {{contact.name}} how are you? ` code: {{contact.name}} ` ` code: {{contact.name}} ` test'
        message.save!
        expect(message.content).to eq 'hey John how are you? ` code: {{contact.name}} ` ` code: {{contact.name}} ` test'
      end

      it 'will not throw error for broken quotes' do
        message.content = 'hey {{contact.name}} how are you? ` code: {{contact.name}} ` ` code: {{contact.name}} test'
        message.save!
        expect(message.content).to eq 'hey John how are you? ` code: {{contact.name}} ` ` code: John test'
      end
    end
  end
end
