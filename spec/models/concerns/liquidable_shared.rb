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
        expect(message.content).to eq 'hey john how are you?'
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

      it 'will not process liquid tags in multiple code blocks' do
        message.content = 'hey {{contact.name}} how are you? ``` code: {{contact.name}} ``` ``` code: {{contact.name}} ``` test'
        message.save!
        expect(message.content).to eq 'hey john how are you? ``` code: {{contact.name}} ``` ``` code: {{contact.name}} ``` test'
      end

      it 'will extract first name from contact name' do
        message.content = 'hey {{contact.first_name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey john how are you?'
      end

      it 'return empty last name when value is not available' do
        message.content = 'hey {{contact.last_name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey  how are you?'
      end

      it 'will extract first name and last name from contact name' do
        contact.name = 'john doe'
        contact.save!
        message.content = 'hey {{contact.first_name}} {{contact.last_name}} how are you?'
        message.save!
        expect(message.content).to eq 'hey john doe how are you?'
      end
    end
  end
end
