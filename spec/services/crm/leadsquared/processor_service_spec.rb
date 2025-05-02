require 'rails_helper'

RSpec.describe Crm::Leadsquared::ProcessorService do
  let(:account) { create(:account) }
  let(:hook) do
    create(:integrations_hook, :leadsquared, account: account, settings: {
             'access_key' => 'test_access_key',
             'secret_key' => 'test_secret_key',
             'endpoint_url' => 'https://api.leadsquared.com/v2',
             'enable_transcript_activity' => true,
             'enable_conversation_activity' => true,
             'conversation_activity_code' => 1001,
             'transcript_activity_code' => 1002
           })
  end
  let(:contact) { create(:contact, account: account, email: 'test@example.com', phone_number: '+1234567890') }
  let(:contact_with_social_profile) do
    create(:contact, account: account, additional_attributes: { 'social_profiles' => { 'facebook' => 'chatwootapp' } })
  end
  let(:blank_contact) { create(:contact, account: account, email: '', phone_number: '') }
  let(:conversation) { create(:conversation, account: account, contact: contact) }
  let(:service) { described_class.new(hook) }
  let(:lead_client) { instance_double(Crm::Leadsquared::Api::LeadClient) }
  let(:activity_client) { instance_double(Crm::Leadsquared::Api::ActivityClient) }
  let(:lead_finder) { instance_double(Crm::Leadsquared::LeadFinderService) }

  before do
    account.enable_features('crm_integration')
    allow(Crm::Leadsquared::Api::LeadClient).to receive(:new)
      .with('test_access_key', 'test_secret_key', 'https://api.leadsquared.com/v2')
      .and_return(lead_client)
    allow(Crm::Leadsquared::Api::ActivityClient).to receive(:new)
      .with('test_access_key', 'test_secret_key', 'https://api.leadsquared.com/v2')
      .and_return(activity_client)
    allow(Crm::Leadsquared::LeadFinderService).to receive(:new)
      .with(lead_client)
      .and_return(lead_finder)
  end

  describe '.crm_name' do
    it 'returns leadsquared' do
      expect(described_class.crm_name).to eq('leadsquared')
    end
  end

  describe '#handle_contact' do
    context 'when contact is valid' do
      before do
        allow(service).to receive(:identifiable_contact?).and_return(true)
      end

      context 'when contact has no stored lead ID' do
        before do
          contact.update!(additional_attributes: { 'external' => nil })
          contact.reload

          allow(lead_client).to receive(:create_or_update_lead)
            .with(any_args)
            .and_return('new_lead_id')
        end

        it 'creates a new lead and stores the ID' do
          service.handle_contact(contact)
          expect(lead_client).to have_received(:create_or_update_lead).with(any_args)
          expect(contact.reload.additional_attributes['external']['leadsquared_id']).to eq('new_lead_id')
        end
      end

      context 'when contact has existing lead ID' do
        before do
          contact.additional_attributes = { 'external' => { 'leadsquared_id' => 'existing_lead_id' } }
          contact.save!

          allow(lead_client).to receive(:update_lead)
            .with(any_args)
            .and_return(nil) # The update method doesn't need to return anything
        end

        it 'updates the lead using existing ID' do
          service.handle_contact(contact)
          expect(lead_client).to have_received(:update_lead).with(any_args)
        end
      end

      context 'when API call raises an error' do
        before do
          allow(lead_client).to receive(:create_or_update_lead)
            .with(any_args)
            .and_raise(Crm::Leadsquared::Api::BaseClient::ApiError.new('API Error'))

          allow(Rails.logger).to receive(:error)
        end

        it 'catches and logs the error' do
          service.handle_contact(contact)
          expect(Rails.logger).to have_received(:error).with(/LeadSquared API error/)
        end
      end
    end

    context 'when contact is invalid' do
      before do
        allow(service).to receive(:identifiable_contact?).and_return(false)
        allow(lead_client).to receive(:create_or_update_lead)
      end

      it 'returns without making API calls' do
        service.handle_contact(blank_contact)
        expect(lead_client).not_to have_received(:create_or_update_lead)
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

    context 'when conversation activities are enabled' do
      before do
        service.instance_variable_set(:@allow_conversation, true)
      end

      context 'when lead_id is found' do
        before do
          allow(lead_finder).to receive(:find_or_create)
            .with(contact)
            .and_return('test_lead_id')

          allow(activity_client).to receive(:post_activity)
            .with('test_lead_id', 1001, activity_note)
            .and_return('test_activity_id')
        end

        it 'creates the activity and stores metadata' do
          service.handle_conversation_created(conversation)
          expect(conversation.reload.additional_attributes['leadsquared']['created_activity_id']).to eq('test_activity_id')
        end
      end

      context 'when post_activity raises an error' do
        before do
          allow(lead_finder).to receive(:find_or_create)
            .with(contact)
            .and_return('test_lead_id')

          allow(activity_client).to receive(:post_activity)
            .with('test_lead_id', 1001, activity_note)
            .and_raise(StandardError.new('Activity error'))

          allow(Rails.logger).to receive(:error)
        end

        it 'logs the error' do
          service.handle_conversation_created(conversation)
          expect(Rails.logger).to have_received(:error).with(/Error creating conversation activity/)
        end
      end
    end

    context 'when conversation activities are disabled' do
      before do
        service.instance_variable_set(:@allow_conversation, false)
        allow(activity_client).to receive(:post_activity)
      end

      it 'does not create an activity' do
        service.handle_conversation_created(conversation)
        expect(activity_client).not_to have_received(:post_activity)
      end
    end
  end

  describe '#handle_conversation_resolved' do
    let(:activity_note) { 'Conversation transcript' }

    before do
      allow(Crm::Leadsquared::Mappers::ConversationMapper).to receive(:map_transcript_activity)
        .with(conversation)
        .and_return(activity_note)
    end

    context 'when transcript activities are enabled and conversation is resolved' do
      before do
        service.instance_variable_set(:@allow_transcript, true)
        conversation.update!(status: 'resolved')

        allow(lead_finder).to receive(:find_or_create)
          .with(contact)
          .and_return('test_lead_id')

        allow(activity_client).to receive(:post_activity)
          .with('test_lead_id', 1002, activity_note)
          .and_return('test_activity_id')
      end

      it 'creates the transcript activity and stores metadata' do
        service.handle_conversation_resolved(conversation)
        expect(conversation.reload.additional_attributes['leadsquared']['transcript_activity_id']).to eq('test_activity_id')
      end
    end

    context 'when conversation is not resolved' do
      before do
        service.instance_variable_set(:@allow_transcript, true)
        conversation.update!(status: 'open')
        allow(activity_client).to receive(:post_activity)
      end

      it 'does not create an activity' do
        service.handle_conversation_resolved(conversation)
        expect(activity_client).not_to have_received(:post_activity)
      end
    end

    context 'when transcript activities are disabled' do
      before do
        service.instance_variable_set(:@allow_transcript, false)
        conversation.update!(status: 'resolved')
        allow(activity_client).to receive(:post_activity)
      end

      it 'does not create an activity' do
        service.handle_conversation_resolved(conversation)
        expect(activity_client).not_to have_received(:post_activity)
      end
    end
  end
end
