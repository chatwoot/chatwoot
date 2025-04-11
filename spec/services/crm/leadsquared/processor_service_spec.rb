require 'rails_helper'

RSpec.describe Crm::Leadsquared::ProcessorService do
  let(:account) { create(:account) }
  let(:hook) do
    create(:integrations_hook, :leadsquared, account: account, settings: {
             'access_key' => 'test_access_key',
             'secret_key' => 'test_secret_key',
             'endpoint_url' => 'https://api.leadsquared.com',
             'conversation_activity_code' => 1001,
             'transcript_activity_code' => 1002
           })
  end
  let(:contact) { create(:contact, account: account, email: 'test@example.com', phone_number: '+1234567890') }
  let(:conversation) { create(:conversation, account: account, contact: contact) }
  let(:service) { described_class.new(hook) }
  let(:lead_client) { instance_double(Crm::Leadsquared::Api::LeadClient) }
  let(:activity_client) { instance_double(Crm::Leadsquared::Api::ActivityClient) }
  let(:lead_success_response) do
    { success: true, data: { 'Status' => 'Success', 'Value' => { 'ProspectId' => 'test_lead_id', 'AffectedRows' => 1 } } }
  end
  let(:lead_search_response) { { success: true, data: [{ 'ProspectID' => 'test_lead_id' }] } }
  let(:activity_success_response) { { success: true, data: { 'Status' => 'Success', 'Value' => { 'Id' => 'test_activity_id' } } } }

  before do
    allow(Crm::Leadsquared::Api::LeadClient).to receive(:new)
      .with('test_access_key', 'test_secret_key', 'https://api.leadsquared.com')
      .and_return(lead_client)
    allow(Crm::Leadsquared::Api::ActivityClient).to receive(:new)
      .with('test_access_key', 'test_secret_key', 'https://api.leadsquared.com')
      .and_return(activity_client)

    # Default stubs for common API calls
    allow(lead_client).to receive(:search_lead)
      .with(any_args)
      .and_return({ success: true, data: [] })
    allow(lead_client).to receive(:create_or_update_lead)
      .with(any_args)
      .and_return(lead_success_response)
  end

  describe '.crm_name' do
    it 'returns leadsquared' do
      expect(described_class.crm_name).to eq('leadsquared')
    end
  end

  describe '#handle_contact_created' do
    context 'when lead creation succeeds' do
      before do
        allow(lead_client).to receive(:create_or_update_lead)
          .with(any_args)
          .and_return(lead_success_response)
      end

      it 'creates the lead and stores external id' do
        result = service.handle_contact_created(contact)
        expect(result[:success]).to be true
        expect(contact.reload.additional_attributes['external']['leadsquared_id']).to eq('test_lead_id')
      end
    end

    context 'when lead creation fails' do
      before do
        allow(lead_client).to receive(:create_or_update_lead)
          .with(any_args)
          .and_return({ success: false, error: 'API Error' })
      end

      it 'returns failure response' do
        result = service.handle_contact_created(contact)
        expect(result[:success]).to be false
        expect(result[:error]).to eq('API Error')
      end
    end
  end

  describe '#handle_contact_updated' do
    context 'when contact has existing leadsquared_id' do
      before do
        contact.additional_attributes = { 'external' => { 'leadsquared_id' => 'test_lead_id' } }
        contact.save!

        allow(lead_client).to receive(:create_or_update_lead)
          .with(any_args)
          .and_return(lead_success_response.merge(
                        data: { 'Status' => 'Success', 'Value' => { 'ProspectId' => 'existing_lead_id', 'AffectedRows' => 1 } }
                      ))
      end

      it 'updates the lead using existing id' do
        result = service.handle_contact_updated(contact)
        expect(result[:success]).to be true
        expect(lead_client).to have_received(:create_or_update_lead).with(any_args)
      end
    end

    context 'when contact has no leadsquared_id' do
      context 'when lead exists in leadsquared' do
        before do
          contact.update(additional_attributes: { 'external' => nil })
          contact.reload

          allow(lead_client).to receive(:create_or_update_lead)
            .with(any_args)
            .and_return(lead_success_response)
        end

        it 'finds and updates the lead' do
          result = service.handle_contact_updated(contact)
          expect(result[:success]).to be true
          expect(contact.reload.additional_attributes['external']['leadsquared_id']).to eq('test_lead_id')
        end
      end

      context 'when lead does not exist in leadsquared' do
        before do
          allow(lead_client).to receive(:create_or_update_lead)
            .with(any_args)
            .and_return(lead_success_response.merge(
                          data: { 'Status' => 'Success', 'Value' => { 'ProspectId' => 'new_lead_id', 'AffectedRows' => 1 } }
                        ))
        end

        it 'creates a new lead' do
          result = service.handle_contact_updated(contact)
          expect(result[:success]).to be true
          expect(lead_client).to have_received(:create_or_update_lead).with(any_args)
        end
      end
    end
  end

  describe '#handle_conversation_created' do
    let(:activity_note) { 'New conversation started' }

    before do
      allow(Crm::Leadsquared::Mappers::ConversationMapper).to receive(:map_conversation_activity)
        .with(conversation)
        .and_return(activity_note)
    end

    context 'when contact has leadsquared_id' do
      before do
        contact.additional_attributes = { 'external' => { 'leadsquared_id' => 'test_lead_id' } }
        contact.save!
      end

      context 'when activity creation succeeds' do
        before do
          allow(activity_client).to receive(:post_activity)
            .with('test_lead_id', 1001, activity_note)
            .and_return(activity_success_response)
        end

        it 'creates the activity and stores metadata' do
          result = service.handle_conversation_created(conversation)
          expect(result[:success]).to be true
          expect(conversation.reload.additional_attributes['leadsquared']['activity_id']).to eq('test_activity_id')
        end
      end

      context 'when activity creation fails' do
        before do
          allow(activity_client).to receive(:post_activity)
            .with('test_lead_id', 1001, activity_note)
            .and_return({ success: false, error: 'API Error' })
        end

        it 'returns failure response' do
          result = service.handle_conversation_created(conversation)
          expect(result[:success]).to be false
          expect(result[:error]).to eq('API Error')
        end
      end
    end

    context 'when contact has no leadsquared_id' do
      before do
        allow(lead_client).to receive(:search_lead)
          .with(contact.email)
          .and_return(lead_search_response)
        allow(activity_client).to receive(:post_activity)
          .with('test_lead_id', 1001, activity_note)
          .and_return(activity_success_response)
      end

      it 'finds lead and creates activity' do
        result = service.handle_conversation_created(conversation)
        expect(result[:success]).to be true
        expect(conversation.reload.additional_attributes['leadsquared']['activity_id']).to eq('test_activity_id')
        expect(contact.reload.additional_attributes['external']['leadsquared_id']).to eq('test_lead_id')
      end
    end
  end

  describe '#handle_conversation_updated' do
    let(:activity_note) { 'Conversation transcript' }

    before do
      allow(Crm::Leadsquared::Mappers::ConversationMapper).to receive(:map_transcript_activity)
        .with(conversation)
        .and_return(activity_note)
    end

    context 'when conversation is resolved' do
      before do
        conversation.update!(status: 'resolved')
        contact.additional_attributes = { 'external' => { 'leadsquared_id' => 'test_lead_id' } }
        contact.save!
      end

      context 'when activity creation succeeds' do
        before do
          allow(activity_client).to receive(:post_activity)
            .with('test_lead_id', 1002, activity_note)
            .and_return(activity_success_response)
        end

        it 'creates the transcript activity and stores metadata' do
          result = service.handle_conversation_updated(conversation)
          expect(result[:success]).to be true
          expect(conversation.reload.additional_attributes['leadsquared']['transcript_activity_id']).to eq('test_activity_id')
        end
      end

      context 'when activity creation fails' do
        before do
          allow(activity_client).to receive(:post_activity)
            .with('test_lead_id', 1002, activity_note)
            .and_return({ success: false, error: 'API Error' })
        end

        it 'returns failure response' do
          result = service.handle_conversation_updated(conversation)
          expect(result[:success]).to be false
          expect(result[:error]).to eq('API Error')
        end
      end
    end

    context 'when conversation is not resolved' do
      before do
        conversation.update!(status: 'open')
        allow(activity_client).to receive(:post_activity)
      end

      it 'returns success without creating activity' do
        result = service.handle_conversation_updated(conversation)
        expect(result[:success]).to be true
        expect(activity_client).not_to have_received(:post_activity)
      end
    end
  end
end
