require 'rails_helper'

RSpec.describe Integrations::Dialogflow::ProcessorService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
  let(:hook) { create(:integrations_hook, app_id: 'dialogflow', account: account) }
  
  let(:event_data) do
    {
      message: message,
      conversation: conversation,
      contact: contact,
      inbox: inbox
    }
  end

  let(:service) { described_class.new(event_data: event_data, hook: hook) }

  describe '#build_whatsapp_payload_data' do
    before do
      # Create SocialWise hook for testing
      create(:integrations_hook, 
             app_id: 'socialwise_chatwit', 
             status: 'enabled', 
             account: account,
             settings: { 'enabled' => true })
    end

    context 'when inbox is not WhatsApp channel' do
      it 'returns payload without WhatsApp API key' do
        result = service.send(:build_whatsapp_payload_data)
        
        expect(result['whatsapp_api_key']).to be_nil
        expect(result['has_whatsapp_api_key']).to be false
        expect(result['is_whatsapp_channel']).to be false
      end

      it 'includes basic payload structure' do
        result = service.send(:build_whatsapp_payload_data)
        
        expect(result).to include(
          'wamid',
          'whatsapp_id',
          'contact_name',
          'contact_phone',
          'conversation_id',
          'inbox_id',
          'message_id',
          'socialwise_active'
        )
      end
    end

    context 'when inbox is WhatsApp channel with API key' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_whatsapp_api_key_123', 'phone_number_id' => 'test_phone_number_id', 'business_account_id' => 'test_business_id' }) }
      let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation) }
      
      let(:whatsapp_event_data) do
        {
          message: whatsapp_message,
          conversation: whatsapp_conversation,
          contact: contact,
          inbox: whatsapp_inbox
        }
      end

      let(:whatsapp_service) { described_class.new(event_data: whatsapp_event_data, hook: hook) }

      it 'includes WhatsApp API key in the payload' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['whatsapp_api_key']).to eq('test_whatsapp_api_key_123')
        expect(result['has_whatsapp_api_key']).to be true
        expect(result['is_whatsapp_channel']).to be true
      end

      it 'includes WhatsApp phone number ID in the payload' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['phone_number_id']).to eq('test_phone_number_id')
      end

      it 'includes WhatsApp business ID in the payload' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['business_id']).to eq('test_business_id')
      end

      it 'includes WhatsApp identifiers' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['wamid']).to eq(whatsapp_message.source_id)
        # whatsapp_id foi removido para evitar duplicação
      end

      it 'includes complete payload structure' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result).to include(
          'wamid',
          'contact_name',
          'contact_phone',
          'conversation_id',
          'inbox_id',
          'message_id',
          'whatsapp_api_key',
          'phone_number_id',
          'business_id',
          'has_whatsapp_api_key',
          'is_whatsapp_channel',
          'socialwise_active',
          'payload_version'
        )
      end

      it 'includes interactive button data when present' do
        # Create message with button interaction
        whatsapp_message.update!(content_attributes: {
          button_reply: { id: 'btn_test_123', title: 'Confirm' },
          interaction_type: 'button_reply'
        })
        
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['button_id']).to eq('btn_test_123')
        expect(result['button_title']).to eq('Confirm')
        expect(result['interaction_type']).to eq('button_reply')
        expect(result['list_id']).to be_nil
      end

      it 'includes interactive list data when present' do
        # Create message with list interaction
        whatsapp_message.update!(content_attributes: {
          list_reply: { 
            id: 'list_test_456', 
            title: 'Option A',
            description: 'First choice'
          },
          interaction_type: 'list_reply'
        })
        
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['list_id']).to eq('list_test_456')
        expect(result['list_title']).to eq('Option A')
        expect(result['list_description']).to eq('First choice')
        expect(result['interaction_type']).to eq('list_reply')
        expect(result['button_id']).to be_nil
      end
    end

    context 'when inbox is WhatsApp channel without API key' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: {}) }
      let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation) }
      
      let(:whatsapp_event_data) do
        {
          message: whatsapp_message,
          conversation: whatsapp_conversation,
          contact: contact,
          inbox: whatsapp_inbox
        }
      end

      let(:whatsapp_service) { described_class.new(event_data: whatsapp_event_data, hook: hook) }

      it 'includes nil WhatsApp API key in the payload' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['whatsapp_api_key']).to be_nil
        expect(result['has_whatsapp_api_key']).to be false
        expect(result['is_whatsapp_channel']).to be true
      end
    end

    context 'when WhatsApp channel has provider_config but no api_key' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: { 'other_key' => 'other_value' }) }
      let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation) }
      
      let(:whatsapp_event_data) do
        {
          message: whatsapp_message,
          conversation: whatsapp_conversation,
          contact: contact,
          inbox: whatsapp_inbox
        }
      end

      let(:whatsapp_service) { described_class.new(event_data: whatsapp_event_data, hook: hook) }

      it 'includes nil WhatsApp API key in the payload' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['whatsapp_api_key']).to be_nil
        expect(result['has_whatsapp_api_key']).to be false
      end
    end

    context 'when an error occurs during API key extraction' do
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_key' }) }
      let(:whatsapp_inbox) { create(:inbox, account: account, channel: whatsapp_channel) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation) }
      
      let(:whatsapp_event_data) do
        {
          message: whatsapp_message,
          conversation: whatsapp_conversation,
          contact: contact,
          inbox: whatsapp_inbox
        }
      end

      let(:whatsapp_service) { described_class.new(event_data: whatsapp_event_data, hook: hook) }

      before do
        # Mock an error when accessing provider_config
        allow(whatsapp_inbox.channel).to receive(:provider_config).and_raise(StandardError, 'Provider config error')
      end

      it 'handles the error gracefully and includes error information in fallback payload' do
        result = whatsapp_service.send(:build_whatsapp_payload_data)
        
        expect(result['whatsapp_api_key']).to be_nil
        expect(result['has_whatsapp_api_key']).to be false
        expect(result['error']).to include('Payload construction failed')
      end
    end

    context 'when using shared SocialWise service' do
      it 'calls the shared SocialWise service to build payload data' do
        expect(Integrations::Socialwise::WebhookEnhancerService).to receive(:enhance_payload).and_call_original
        
        service.send(:build_whatsapp_payload_data)
      end

      it 'converts nested SocialWise data to flat structure for Dialogflow compatibility' do
        result = service.send(:build_whatsapp_payload_data)
        
        # Should have flat structure, not nested socialwise-chatwit
        expect(result).not_to have_key('socialwise-chatwit')
        expect(result).to include(
          'contact_name',
          'conversation_id',
          'message_id',
          'inbox_id',
          'account_id'
        )
      end

      it 'merges contact custom attributes at root level for backward compatibility' do
        contact.update!(custom_attributes: { 'whatsapp_token' => 'test_token_123', 'custom_field' => 'custom_value' })
        
        result = service.send(:build_whatsapp_payload_data)
        
        expect(result['whatsapp_token']).to eq('test_token_123')
        expect(result['custom_field']).to eq('custom_value')
      end
    end
  end

  describe '#socialwise_chatwit_enabled?' do
    context 'when SocialWise hook is not present' do
      it 'returns false' do
        expect(service.send(:socialwise_chatwit_enabled?)).to be false
      end
    end

    context 'when SocialWise hook is present and enabled' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'returns true' do
        expect(service.send(:socialwise_chatwit_enabled?)).to be true
      end

      it 'uses shared SocialWise service to check activation' do
        expect(Integrations::Socialwise::WebhookEnhancerService).to receive(:socialwise_active?).with(account).and_call_original
        
        service.send(:socialwise_chatwit_enabled?)
      end
    end

    context 'when SocialWise hook is present but disabled' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => false })
      end

      it 'returns false' do
        expect(service.send(:socialwise_chatwit_enabled?)).to be false
      end
    end
  end

  describe 'backward compatibility' do
    before do
      create(:integrations_hook, 
             app_id: 'socialwise_chatwit', 
             status: 'enabled', 
             account: account,
             settings: { 'enabled' => true })
    end

    context 'when maintaining existing Dialogflow payload structure' do
      it 'maintains flat payload structure instead of nested socialwise-chatwit' do
        result = service.send(:build_whatsapp_payload_data)
        
        # Should not have nested structure
        expect(result).not_to have_key('socialwise-chatwit')
        
        # Should have flat structure for backward compatibility
        expect(result).to include(
          'wamid',
          'contact_name',
          'contact_phone',
          'conversation_id',
          'message_id',
          'inbox_id',
          'account_id',
          'whatsapp_api_key',
          'phone_number_id',
          'business_id',
          'socialwise_active'
        )
      end

      it 'preserves existing field names and data types' do
        result = service.send(:build_whatsapp_payload_data)
        
        # Check specific field names that existing integrations expect
        expect(result['contact_name']).to eq(contact.name)
        expect(result['contact_phone']).to eq(contact.phone_number)
        expect(result['conversation_id']).to eq(conversation.id)
        expect(result['message_id']).to eq(message.id)
        expect(result['inbox_id']).to eq(inbox.id)
        expect(result['account_id']).to eq(account.id)
        
        # Check data types
        expect(result['conversation_id']).to be_a(Integer)
        expect(result['message_id']).to be_a(Integer)
        expect(result['socialwise_active']).to be_a(TrueClass)
      end

      it 'merges contact custom_attributes at root level for backward compatibility' do
        contact.update!(custom_attributes: { 
          'whatsapp_token' => 'legacy_token_123',
          'customer_type' => 'premium',
          'source' => 'website'
        })
        
        result = service.send(:build_whatsapp_payload_data)
        
        # Custom attributes should be at root level, not nested
        expect(result['whatsapp_token']).to eq('legacy_token_123')
        expect(result['customer_type']).to eq('premium')
        expect(result['source']).to eq('website')
        
        # Should not have nested custom_attributes
        expect(result).not_to have_key('custom_attributes')
      end

      it 'maintains timestamp format compatibility' do
        result = service.send(:build_whatsapp_payload_data)
        
        # Check ISO8601 format for timestamps
        expect(result['conversation_created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(result['conversation_updated_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(result['message_created_at']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        expect(result['timestamp']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
      end

      it 'preserves WhatsApp identifier fields' do
        message.update!(source_id: 'wamid.test123456')
        
        result = service.send(:build_whatsapp_payload_data)
        
        expect(result['wamid']).to eq('wamid.test123456')
        # whatsapp_id foi removido para evitar duplicação
      end
    end

    context 'when existing Dialogflow integrations process the payload' do
      it 'provides all expected fields for existing integrations' do
        result = service.send(:build_whatsapp_payload_data)
        
        # Fields that existing Dialogflow integrations expect
        expected_fields = [
          'wamid', 'contact_name', 'contact_phone', 'contact_email',
          'contact_identifier', 'contact_id', 'conversation_id', 'conversation_status',
          'conversation_assignee_id', 'conversation_created_at', 'conversation_updated_at',
          'message_id', 'message_content', 'message_type', 'message_created_at',
          'message_content_type', 'inbox_id', 'inbox_name', 'channel_type',
          'account_id', 'account_name', 'contact_source', 'whatsapp_api_key',
          'phone_number_id', 'business_id', 'socialwise_active', 'is_whatsapp_channel', 
          'has_whatsapp_api_key', 'payload_version', 'timestamp', 'button_id',
          'button_title', 'list_id', 'list_title', 'list_description', 'interaction_type'
        ]
        
        expected_fields.each do |field|
          expect(result).to have_key(field), "Expected field '#{field}' to be present in payload"
        end
      end

      it 'handles nil values gracefully for backward compatibility' do
        # Set some fields to nil to test graceful handling
        contact.update!(email: nil, identifier: nil)
        conversation.update!(assignee_id: nil)
        
        result = service.send(:build_whatsapp_payload_data)
        
        expect(result['contact_email']).to be_nil
        expect(result['contact_identifier']).to be_nil
        expect(result['conversation_assignee_id']).to be_nil
        
        # Should not raise errors and should include the fields
        expect(result).to have_key('contact_email')
        expect(result).to have_key('contact_identifier')
        expect(result).to have_key('conversation_assignee_id')
      end

      it 'maintains error handling structure for backward compatibility' do
        # Mock an error in the shared service
        allow(Integrations::Socialwise::WebhookEnhancerService).to receive(:enhance_payload).and_raise(StandardError, 'Service error')
        
        result = service.send(:build_whatsapp_payload_data)
        
        # Should return fallback payload with expected structure
        expect(result).to include(
          'wamid',
          'contact_name',
          'socialwise_active',
          'whatsapp_api_key',
          'phone_number_id',
          'business_id',
          'has_whatsapp_api_key',
          'error'
        )
        
        expect(result['error']).to include('Payload construction failed')
        expect(result['socialwise_active']).to be true
        expect(result['whatsapp_api_key']).to be_nil
        expect(result['has_whatsapp_api_key']).to be false
      end
    end

    context 'when Dialogflow functionality remains unaffected' do
      it 'does not interfere with existing Dialogflow processing' do
        # This test ensures that the SocialWise changes don't break Dialogflow
        expect(service).to respond_to(:get_response)
        expect(service).to respond_to(:process_response)
        expect(service).to respond_to(:detect_intent)
        
        # The service should still have all its original methods
        expect(service.private_methods).to include(:configure_dialogflow_client_defaults)
        expect(service.private_methods).to include(:build_session_path)
        expect(service.private_methods).to include(:hash_to_struct)
      end

      it 'maintains originalDetectIntentRequest payload structure' do
        # The payload built by build_whatsapp_payload_data should be suitable
        # for inclusion in originalDetectIntentRequest.payload
        result = service.send(:build_whatsapp_payload_data)
        
        # Should be a flat hash suitable for Dialogflow's originalDetectIntentRequest.payload
        expect(result).to be_a(Hash)
        expect(result.keys).to all(be_a(String))
        
        # Should not have deeply nested structures that would break Dialogflow
        result.values.each do |value|
          expect(value).not_to be_a(Hash) unless value.nil?
        end
      end
    end
  end
end
