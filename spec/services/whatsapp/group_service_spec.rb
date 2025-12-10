# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Whatsapp::GroupService do
  let(:account) { create(:account) }
  let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider: 'whatsapp_light') }
  let(:inbox) do
    create(:inbox, account: account, channel: whatsapp_channel, auto_assignment_config: {
             'assignment_type' => 'group',
             'max_assignment_limit' => 10
           })
  end
  let(:agent) { create(:user, account: account, phone_number: '+1234567890') }
  let(:contact) { create(:contact, account: account, phone_number: '+9876543210') }
  let(:conversation) { create(:conversation, inbox: inbox, assignee: agent, contact: contact) }
  let(:service) { described_class.new(conversation: conversation) }

  before do
    ENV['WHAPI_ADMIN_CHANNEL_TOKEN'] = 'test_admin_token'
    ENV['WHAPI_GATE_URL'] = 'https://gate.whapi.cloud'
  end

  after do
    ENV.delete('WHAPI_ADMIN_CHANNEL_TOKEN')
    ENV.delete('WHAPI_GATE_URL')
  end

  describe '#create_group' do
    context 'when all conditions are met' do
      let(:whapi_response) do
        {
          group_id: '120363402679040508@g.us',
          participants: [
            { id: '1234567890@lid', phone: '1234567890' },
            { id: '9876543210@lid', phone: '9876543210' }
          ]
        }
      end

      before do
        stub_request(:post, "#{ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')}/groups")
          .to_return(status: 200, body: whapi_response.to_json)
      end

      it 'creates a WhatsApp group successfully' do
        group_id = service.create_group
        expect(group_id).to eq('120363402679040508@g.us')
      end

      it 'updates conversation metadata with group_id' do
        service.create_group
        expect(conversation.reload.additional_attributes['whatsapp_group_id']).to eq('120363402679040508@g.us')
      end

      it 'updates conversation with group metadata' do
        service.create_group

        conversation.reload
        expect(conversation.additional_attributes['type']).to eq('group')
        expect(conversation.additional_attributes['whatsapp_group_id']).to eq('120363402679040508@g.us')
        expect(conversation.additional_attributes['participant_ids']).to eq(['1234567890@lid', '9876543210@lid'])
      end

      it 'stores the group_id for future ContactInbox creation' do
        result = service.create_group

        # Verificar que el servicio devuelve el group_id
        expect(result).to eq('120363402679040508@g.us')

        # Verificar que el group_id está en la metadata de la conversación
        conversation.reload
        expect(conversation.additional_attributes['whatsapp_group_id']).to eq('120363402679040508@g.us')
      end

      it 'maps participants with their Whapi IDs' do
        service.create_group

        conversation.reload
        participants = conversation.additional_attributes['participants']

        expect(participants).to be_an(Array)
        expect(participants.length).to eq(2)
        expect(participants.first).to have_key('whapi_id')
        expect(participants.first).to have_key('phone')
        expect(participants.first).to have_key('contact_id')
        expect(participants.first).to have_key('user_id')
      end

      it 'sends correct payload to Whapi API' do
        service.create_group
        expect(WebMock).to have_requested(:post, "#{ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')}/groups")
          .with(
            headers: {
              'Authorization' => "Bearer #{ENV.fetch('WHAPI_ADMIN_CHANNEL_TOKEN')}",
              'Content-Type' => 'application/json'
            },
            body: hash_including(
              subject: "Conversación ##{conversation.display_id} - #{inbox.name}",
              participants: match_array(['1234567890', '9876543210'])
            )
          )
      end
    end

    context 'when assignment_type is individual' do
      before do
        inbox.update!(auto_assignment_config: { 'assignment_type' => 'individual' })
      end

      it 'does not create a group' do
        result = service.create_group
        expect(result).to be_nil
        expect(WebMock).not_to have_requested(:post, /groups/)
      end
    end

    context 'when agent does not have phone number' do
      before do
        agent.update!(phone_number: nil)
      end

      it 'does not create a group' do
        result = service.create_group
        expect(result).to be_nil
        expect(WebMock).not_to have_requested(:post, /groups/)
      end
    end

    context 'when contact does not have phone number' do
      before do
        contact.update!(phone_number: nil)
      end

      it 'does not create a group' do
        result = service.create_group
        expect(result).to be_nil
        expect(WebMock).not_to have_requested(:post, /groups/)
      end
    end

    context 'when Whapi API returns error' do
      before do
        stub_request(:post, "#{ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')}/groups")
          .to_return(status: 400, body: { error: 'Bad request' }.to_json)
      end

      it 'returns nil and does not crash' do
        result = service.create_group
        expect(result).to be_nil
      end
    end

    context 'when network error occurs' do
      before do
        stub_request(:post, "#{ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')}/groups")
          .to_raise(StandardError.new('Network error'))
      end

      it 'handles error gracefully' do
        expect(Rails.logger).to receive(:error).with(/Error creating group/)
        result = service.create_group
        expect(result).to be_nil
      end
    end
  end

  describe 'phone number formatting' do
    let(:different_agent) { create(:user, account: account, phone_number: '+9999999999') }
    let(:contact_with_spaces) { create(:contact, account: account, phone_number: '+1234567890') }
    let(:conversation_with_spaces) { create(:conversation, inbox: inbox, assignee: different_agent, contact: contact_with_spaces) }

    it 'formats phone numbers correctly by removing +' do
      service_with_spaces = described_class.new(conversation: conversation_with_spaces)

      stub_request(:post, "#{ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')}/groups")
        .to_return(status: 200, body: { group_id: 'test_group_123' }.to_json)

      service_with_spaces.create_group

      expect(WebMock).to have_requested(:post, "#{ENV.fetch('WHAPI_GATE_URL', 'https://gate.whapi.cloud')}/groups")
        .with(body: hash_including(participants: match_array(['1234567890', '9999999999'])))
    end
  end
end
