require 'rails_helper'

RSpec.describe Integrations::Socialwise::WebhookEnhancerService do
  let(:account) { create(:account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox, contact: contact) }
  let(:message) { create(:message, account: account, inbox: inbox, conversation: conversation) }
  
  let(:webhook_payload) do
    {
      event: 'message_created',
      message: message,
      conversation: conversation,
      contact: contact,
      inbox: inbox
    }
  end

  describe '.socialwise_active?' do
    context 'when SocialWise hook is not present' do
      it 'returns false' do
        expect(described_class.socialwise_active?(account)).to be false
      end
    end

    context 'when SocialWise hook is disabled' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'disabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'returns false' do
        expect(described_class.socialwise_active?(account)).to be false
      end
    end

    context 'when SocialWise hook is enabled but settings disabled' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => false })
      end

      it 'returns false' do
        expect(described_class.socialwise_active?(account)).to be false
      end
    end

    context 'when SocialWise hook is enabled and settings enabled as boolean' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'returns true' do
        expect(described_class.socialwise_active?(account)).to be true
      end
    end

    context 'when SocialWise hook is enabled and settings enabled as string' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => 'true' })
      end

      it 'returns true' do
        expect(described_class.socialwise_active?(account)).to be true
      end
    end
  end

  describe '.enhance_payload' do
    context 'when SocialWise is not active' do
      it 'returns the original payload unchanged' do
        result = described_class.enhance_payload(webhook_payload, account)
        expect(result).to eq(webhook_payload)
      end
    end

    context 'when SocialWise is active' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'returns enhanced payload with socialwise-chatwit data' do
        result = described_class.enhance_payload(webhook_payload, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']).to be_a(Hash)
        expect(result['socialwise-chatwit']).to include(
          'whatsapp_identifiers',
          'contact_data',
          'conversation_data',
          'message_data',
          'inbox_data',
          'account_data',
          'metadata',
          'whatsapp_api_key',
          'whatsapp_phone_number_id',
          'whatsapp_business_id'
        )
      end

      it 'includes correct metadata' do
        result = described_class.enhance_payload(webhook_payload, account)
        metadata = result['socialwise-chatwit']['metadata']
        
        expect(metadata['socialwise_active']).to be true
        expect(metadata['payload_version']).to eq('2.0')
        expect(metadata['timestamp']).to be_present
        expect(metadata['has_whatsapp_api_key']).to be false # Default inbox is not WhatsApp
      end

      it 'includes contact data' do
        result = described_class.enhance_payload(webhook_payload, account)
        contact_data = result['socialwise-chatwit']['contact_data']
        
        expect(contact_data['id']).to eq(contact.id)
        expect(contact_data['name']).to eq(contact.name)
        expect(contact_data['custom_attributes']).to be_a(Hash)
      end

      it 'includes conversation data' do
        result = described_class.enhance_payload(webhook_payload, account)
        conversation_data = result['socialwise-chatwit']['conversation_data']
        
        expect(conversation_data['id']).to eq(conversation.id)
        expect(conversation_data['status']).to eq(conversation.status)
      end

      it 'includes message data' do
        result = described_class.enhance_payload(webhook_payload, account)
        message_data = result['socialwise-chatwit']['message_data']
        
        expect(message_data['id']).to eq(message.id)
        expect(message_data['content']).to eq(message.content)
        expect(message_data['interactive_data']).to be_a(Hash)
      end

      it 'includes inbox data' do
        result = described_class.enhance_payload(webhook_payload, account)
        inbox_data = result['socialwise-chatwit']['inbox_data']
        
        expect(inbox_data['id']).to eq(inbox.id)
        expect(inbox_data['name']).to eq(inbox.name)
      end

      it 'includes account data' do
        result = described_class.enhance_payload(webhook_payload, account)
        account_data = result['socialwise-chatwit']['account_data']
        
        expect(account_data['id']).to eq(account.id)
        expect(account_data['name']).to eq(account.name)
      end

      it 'includes whatsapp_api_key field' do
        result = described_class.enhance_payload(webhook_payload, account)
        whatsapp_api_key = result['socialwise-chatwit']['whatsapp_api_key']
        
        expect(whatsapp_api_key).to be_nil # Default inbox is not WhatsApp
      end

      it 'includes interactive data for button messages' do
        # Create a message with interactive button data
        interactive_message = create(:message, 
                                   account: account, 
                                   inbox: inbox, 
                                   conversation: conversation,
                                   content_attributes: {
                                     button_reply: { id: 'btn_123', title: 'Yes' },
                                     interaction_type: 'button_reply'
                                   })
        
        interactive_payload = webhook_payload.merge(message: interactive_message)
        result = described_class.enhance_payload(interactive_payload, account)
        
        interactive_data = result['socialwise-chatwit']['message_data']['interactive_data']
        expect(interactive_data['button_id']).to eq('btn_123')
        expect(interactive_data['button_title']).to eq('Yes')
        expect(interactive_data['interaction_type']).to eq('button_reply')
      end

      it 'includes interactive data for list messages' do
        # Create a message with interactive list data
        interactive_message = create(:message, 
                                   account: account, 
                                   inbox: inbox, 
                                   conversation: conversation,
                                   content_attributes: {
                                     list_reply: { 
                                       id: 'list_456', 
                                       title: 'Option 1',
                                       description: 'First option'
                                     },
                                     interaction_type: 'list_reply'
                                   })
        
        interactive_payload = webhook_payload.merge(message: interactive_message)
        result = described_class.enhance_payload(interactive_payload, account)
        
        interactive_data = result['socialwise-chatwit']['message_data']['interactive_data']
        expect(interactive_data['list_id']).to eq('list_456')
        expect(interactive_data['list_title']).to eq('Option 1')
        expect(interactive_data['list_description']).to eq('First option')
        expect(interactive_data['interaction_type']).to eq('list_reply')
      end
    end

    context 'when SocialWise is active and inbox is WhatsApp' do
      let(:whatsapp_inbox) { create(:inbox, account: account) }
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_whatsapp_api_key', 'phone_number_id' => 'test_phone_number_id', 'business_account_id' => 'test_business_id' }) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation) }
      
      let(:whatsapp_webhook_payload) do
        {
          event: 'message_created',
          message: whatsapp_message,
          conversation: whatsapp_conversation,
          contact: contact,
          inbox: whatsapp_inbox
        }
      end

      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
        
        # Associate WhatsApp channel with inbox
        whatsapp_inbox.update!(channel: whatsapp_channel)
      end

      it 'includes WhatsApp API key in the payload' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        whatsapp_api_key = result['socialwise-chatwit']['whatsapp_api_key']
        
        expect(whatsapp_api_key).to eq('test_whatsapp_api_key')
      end

      it 'includes WhatsApp phone number ID in the payload' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        phone_number_id = result['socialwise-chatwit']['whatsapp_phone_number_id']
        
        expect(phone_number_id).to eq('test_phone_number_id')
      end

      it 'includes WhatsApp business ID in the payload' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        business_id = result['socialwise-chatwit']['whatsapp_business_id']
        
        expect(business_id).to eq('test_business_id')
      end

      it 'indicates WhatsApp API key is present in metadata' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        metadata = result['socialwise-chatwit']['metadata']
        
        expect(metadata['has_whatsapp_api_key']).to be true
        expect(metadata['is_whatsapp_channel']).to be true
      end

      it 'includes WhatsApp identifiers' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        whatsapp_identifiers = result['socialwise-chatwit']['whatsapp_identifiers']
        
        expect(whatsapp_identifiers['wamid']).to eq(whatsapp_message.source_id)
        expect(whatsapp_identifiers['whatsapp_id']).to eq(whatsapp_message.source_id)
      end
    end

    context 'when SocialWise is active but WhatsApp channel has no API key' do
      let(:whatsapp_inbox) { create(:inbox, account: account) }
      let(:whatsapp_channel) { create(:channel_whatsapp, account: account, provider_config: {}) }
      let(:whatsapp_conversation) { create(:conversation, account: account, inbox: whatsapp_inbox, contact: contact) }
      let(:whatsapp_message) { create(:message, account: account, inbox: whatsapp_inbox, conversation: whatsapp_conversation) }
      
      let(:whatsapp_webhook_payload) do
        {
          event: 'message_created',
          message: whatsapp_message,
          conversation: whatsapp_conversation,
          contact: contact,
          inbox: whatsapp_inbox
        }
      end

      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
        
        # Associate WhatsApp channel with inbox
        whatsapp_inbox.update!(channel: whatsapp_channel)
      end

      it 'includes nil WhatsApp API key in the payload' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        whatsapp_api_key = result['socialwise-chatwit']['whatsapp_api_key']
        
        expect(whatsapp_api_key).to be_nil
      end

      it 'includes nil WhatsApp phone number ID in the payload' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        phone_number_id = result['socialwise-chatwit']['whatsapp_phone_number_id']
        
        expect(phone_number_id).to be_nil
      end

      it 'includes nil WhatsApp business ID in the payload' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        business_id = result['socialwise-chatwit']['whatsapp_business_id']
        
        expect(business_id).to be_nil
      end

      it 'indicates WhatsApp API key is not present in metadata' do
        result = described_class.enhance_payload(whatsapp_webhook_payload, account)
        metadata = result['socialwise-chatwit']['metadata']
        
        expect(metadata['has_whatsapp_api_key']).to be false
        expect(metadata['is_whatsapp_channel']).to be true
      end
    end

    context 'when error occurs during data collection' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'returns fallback data structure when message extraction fails' do
        # Mock message to raise error
        allow_any_instance_of(described_class).to receive(:safe_extract_message_from_payload).and_raise(StandardError, 'Message extraction failed')
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']['metadata']['error']).to include('Data collection failed')
        expect(result['socialwise-chatwit']['metadata']['fallback_used']).to be true
      end

      it 'continues webhook delivery when SocialWise enhancement fails' do
        # Mock the entire enhancement to fail
        allow(described_class).to receive(:build_socialwise_data).and_raise(StandardError, 'Enhancement failed')
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        # Should return original payload when enhancement fails
        expect(result).to eq(webhook_payload)
      end

      it 'handles WhatsApp API key extraction errors gracefully' do
        whatsapp_inbox = create(:inbox, account: account)
        whatsapp_channel = create(:channel_whatsapp, account: account, provider_config: { 'api_key' => 'test_key' })
        whatsapp_inbox.update!(channel: whatsapp_channel)
        
        whatsapp_payload = webhook_payload.merge(inbox: whatsapp_inbox)
        
        # Mock provider_config to raise error
        allow(whatsapp_channel).to receive(:provider_config).and_raise(StandardError, 'Provider config error')
        
        result = described_class.enhance_payload(whatsapp_payload, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']['whatsapp_api_key']).to be_nil
        expect(result['socialwise-chatwit']['metadata']['has_whatsapp_api_key']).to be false
      end

      it 'logs errors appropriately during data collection' do
        allow(Rails.logger).to receive(:error)
        allow_any_instance_of(described_class).to receive(:safe_extract_message_from_payload).and_raise(StandardError, 'Test error')
        
        described_class.enhance_payload(webhook_payload, account)
        
        expect(Rails.logger).to have_received(:error).with(match(/SOCIALWISE.*Critical error building socialwise-chatwit data/))
      end

      it 'includes comprehensive fallback data structure' do
        allow_any_instance_of(described_class).to receive(:build_socialwise_data).and_raise(StandardError, 'Test error')
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        fallback_data = result['socialwise-chatwit']
        
        expect(fallback_data).to include(
          'whatsapp_identifiers',
          'contact_data',
          'conversation_data',
          'message_data',
          'inbox_data',
          'account_data',
          'metadata',
          'whatsapp_api_key',
          'whatsapp_phone_number_id',
          'whatsapp_business_id'
        )
        
        expect(fallback_data['metadata']['fallback_used']).to be true
        expect(fallback_data['metadata']['error']).to include('Data collection failed')
      end
    end

    context 'when payload has missing or nil objects' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'handles missing message gracefully' do
        payload_without_message = webhook_payload.except(:message)
        
        result = described_class.enhance_payload(payload_without_message, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']['message_data']['id']).to be_nil
        expect(result['socialwise-chatwit']['whatsapp_identifiers']['wamid']).to be_nil
      end

      it 'handles missing contact gracefully' do
        payload_without_contact = webhook_payload.except(:contact)
        
        result = described_class.enhance_payload(payload_without_contact, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']['contact_data']['id']).to be_nil
        expect(result['socialwise-chatwit']['contact_data']['name']).to be_nil
      end

      it 'handles missing conversation gracefully' do
        payload_without_conversation = webhook_payload.except(:conversation)
        
        result = described_class.enhance_payload(payload_without_conversation, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']['conversation_data']['id']).to be_nil
        expect(result['socialwise-chatwit']['conversation_data']['status']).to be_nil
      end

      it 'handles missing inbox gracefully' do
        payload_without_inbox = webhook_payload.except(:inbox)
        
        result = described_class.enhance_payload(payload_without_inbox, account)
        
        expect(result).to include('socialwise-chatwit')
        expect(result['socialwise-chatwit']['inbox_data']['id']).to be_nil
        expect(result['socialwise-chatwit']['metadata']['is_whatsapp_channel']).to be false
      end
    end

    context 'when objects have nil or missing attributes' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'handles contact with nil custom_attributes' do
        contact.update!(custom_attributes: nil)
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        expect(result['socialwise-chatwit']['contact_data']['custom_attributes']).to eq({})
      end

      it 'handles message with nil source_id' do
        message.update!(source_id: nil)
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        expect(result['socialwise-chatwit']['whatsapp_identifiers']['wamid']).to be_nil
        expect(result['socialwise-chatwit']['whatsapp_identifiers']['whatsapp_id']).to be_nil
      end

      it 'handles conversation with nil timestamps' do
        # Mock timestamps to be nil
        allow(conversation).to receive(:created_at).and_return(nil)
        allow(conversation).to receive(:updated_at).and_return(nil)
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        expect(result['socialwise-chatwit']['conversation_data']['created_at']).to be_nil
        expect(result['socialwise-chatwit']['conversation_data']['updated_at']).to be_nil
      end
    end

    context 'when account is nil' do
      it 'handles nil account gracefully in socialwise_active check' do
        expect(described_class.socialwise_active?(nil)).to be false
      end

      it 'handles nil account gracefully in enhance_payload' do
        result = described_class.enhance_payload(webhook_payload, nil)
        
        expect(result).to eq(webhook_payload)
      end
    end

    context 'when hook settings have different formats' do
      it 'handles hook with nil settings' do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: nil)
        
        expect(described_class.socialwise_active?(account)).to be false
      end

      it 'handles hook with empty settings' do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: {})
        
        expect(described_class.socialwise_active?(account)).to be false
      end

      it 'handles hook with string "false" setting' do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => 'false' })
        
        expect(described_class.socialwise_active?(account)).to be false
      end
    end

    context 'payload validation' do
      before do
        create(:integrations_hook, 
               app_id: 'socialwise_chatwit', 
               status: 'enabled', 
               account: account,
               settings: { 'enabled' => true })
      end

      it 'validates complete socialwise-chatwit data structure' do
        result = described_class.enhance_payload(webhook_payload, account)
        socialwise_data = result['socialwise-chatwit']
        
        # Should pass validation
        expect(described_class.send(:validate_socialwise_data, socialwise_data)).to be true
      end

      it 'validates required top-level keys' do
        incomplete_data = {
          'whatsapp_identifiers' => {},
          'contact_data' => {},
          # Missing other required keys
        }
        
        expect(described_class.send(:validate_socialwise_data, incomplete_data)).to be false
      end

      it 'validates whatsapp_identifiers structure' do
        valid_identifiers = {
          'wamid' => 'test_wamid',
          'whatsapp_id' => 'test_whatsapp_id',
          'contact_source' => 'test_source'
        }
        
        expect(described_class.send(:validate_whatsapp_identifiers, valid_identifiers)).to be true
        
        # Test with missing keys
        invalid_identifiers = { 'wamid' => 'test' }
        expect(described_class.send(:validate_whatsapp_identifiers, invalid_identifiers)).to be false
        
        # Test with invalid types
        invalid_types = {
          'wamid' => 123,
          'whatsapp_id' => 'test',
          'contact_source' => 'test'
        }
        expect(described_class.send(:validate_whatsapp_identifiers, invalid_types)).to be false
      end

      it 'validates contact_data structure' do
        valid_contact = {
          'id' => 1,
          'name' => 'Test User',
          'phone_number' => '+1234567890',
          'email' => 'test@example.com',
          'identifier' => 'test_id',
          'custom_attributes' => { 'key' => 'value' }
        }
        
        expect(described_class.send(:validate_contact_data, valid_contact)).to be true
        
        # Test with invalid id type
        invalid_contact = valid_contact.merge('id' => 'not_integer')
        expect(described_class.send(:validate_contact_data, invalid_contact)).to be false
        
        # Test with invalid custom_attributes type
        invalid_attributes = valid_contact.merge('custom_attributes' => 'not_hash')
        expect(described_class.send(:validate_contact_data, invalid_attributes)).to be false
      end

      it 'validates conversation_data structure' do
        valid_conversation = {
          'id' => 1,
          'status' => 'open',
          'assignee_id' => 2,
          'created_at' => '2025-01-19T10:00:00Z',
          'updated_at' => '2025-01-19T10:30:00Z'
        }
        
        expect(described_class.send(:validate_conversation_data, valid_conversation)).to be true
        
        # Test with invalid timestamp format
        invalid_timestamp = valid_conversation.merge('created_at' => 'invalid_timestamp')
        expect(described_class.send(:validate_conversation_data, invalid_timestamp)).to be false
        
        # Test with invalid id type
        invalid_id = valid_conversation.merge('id' => 'not_integer')
        expect(described_class.send(:validate_conversation_data, invalid_id)).to be false
      end

      it 'validates message_data structure' do
        valid_message = {
          'id' => 1,
          'content' => 'Test message',
          'content_type' => 'text',
          'message_type' => 'incoming',
          'created_at' => '2025-01-19T10:00:00Z',
          'interactive_data' => {}
        }
        
        expect(described_class.send(:validate_message_data, valid_message)).to be true
        
        # Test with invalid timestamp
        invalid_timestamp = valid_message.merge('created_at' => 'invalid')
        expect(described_class.send(:validate_message_data, invalid_timestamp)).to be false
        
        # Test with invalid interactive_data type
        invalid_interactive = valid_message.merge('interactive_data' => 'not_hash')
        expect(described_class.send(:validate_message_data, invalid_interactive)).to be false
      end

      it 'validates inbox_data structure' do
        valid_inbox = {
          'id' => 1,
          'name' => 'Test Inbox',
          'channel_type' => 'Channel::Whatsapp'
        }
        
        expect(described_class.send(:validate_inbox_data, valid_inbox)).to be true
        
        # Test with invalid id type
        invalid_inbox = valid_inbox.merge('id' => 'not_integer')
        expect(described_class.send(:validate_inbox_data, invalid_inbox)).to be false
      end

      it 'validates account_data structure' do
        valid_account = {
          'id' => 1,
          'name' => 'Test Account'
        }
        
        expect(described_class.send(:validate_account_data, valid_account)).to be true
        
        # Test with missing keys
        invalid_account = { 'id' => 1 }
        expect(described_class.send(:validate_account_data, invalid_account)).to be false
      end

      it 'validates metadata structure' do
        valid_metadata = {
          'socialwise_active' => true,
          'is_whatsapp_channel' => false,
          'payload_version' => '2.0',
          'timestamp' => '2025-01-19T10:00:00Z',
          'has_whatsapp_api_key' => false
        }
        
        expect(described_class.send(:validate_metadata, valid_metadata)).to be true
        
        # Test with invalid boolean type
        invalid_boolean = valid_metadata.merge('socialwise_active' => 'not_boolean')
        expect(described_class.send(:validate_metadata, invalid_boolean)).to be false
        
        # Test with invalid payload_version
        invalid_version = valid_metadata.merge('payload_version' => '1.0')
        expect(described_class.send(:validate_metadata, invalid_version)).to be false
        
        # Test with invalid timestamp format
        invalid_timestamp = valid_metadata.merge('timestamp' => 'invalid')
        expect(described_class.send(:validate_metadata, invalid_timestamp)).to be false
      end

      it 'validates whatsapp_api_key field' do
        valid_data_with_key = {
          'whatsapp_identifiers' => { 'wamid' => nil, 'whatsapp_id' => nil, 'contact_source' => nil },
          'contact_data' => { 'id' => nil, 'name' => nil, 'phone_number' => nil, 'email' => nil, 'identifier' => nil, 'custom_attributes' => {} },
          'conversation_data' => { 'id' => nil, 'status' => nil, 'assignee_id' => nil, 'created_at' => nil, 'updated_at' => nil },
          'message_data' => { 'id' => nil, 'content' => nil, 'content_type' => nil, 'message_type' => nil, 'created_at' => nil },
          'inbox_data' => { 'id' => nil, 'name' => nil, 'channel_type' => nil },
          'account_data' => { 'id' => nil, 'name' => nil },
          'metadata' => { 'socialwise_active' => true, 'is_whatsapp_channel' => false, 'payload_version' => '2.0', 'timestamp' => '2025-01-19T10:00:00Z', 'has_whatsapp_api_key' => false },
          'whatsapp_api_key' => 'test_api_key',
          'whatsapp_phone_number_id' => 'test_phone_id',
          'whatsapp_business_id' => 'test_business_id'
        }
        
        expect(described_class.send(:validate_socialwise_data, valid_data_with_key)).to be true
        
        # Test with nil api_key
        valid_data_nil_key = valid_data_with_key.merge('whatsapp_api_key' => nil, 'whatsapp_phone_number_id' => nil, 'whatsapp_business_id' => nil)
        expect(described_class.send(:validate_socialwise_data, valid_data_nil_key)).to be true
        
        # Test with invalid api_key type
        invalid_data = valid_data_with_key.merge('whatsapp_api_key' => 123)
        expect(described_class.send(:validate_socialwise_data, invalid_data)).to be false
        
        # Test with invalid phone_number_id type
        invalid_phone_id = valid_data_with_key.merge('whatsapp_phone_number_id' => 123)
        expect(described_class.send(:validate_socialwise_data, invalid_phone_id)).to be false
        
        # Test with invalid business_id type
        invalid_business_id = valid_data_with_key.merge('whatsapp_business_id' => 123)
        expect(described_class.send(:validate_socialwise_data, invalid_business_id)).to be false
      end

      it 'uses fallback data when validation fails' do
        # Mock validation to fail
        allow(described_class).to receive(:validate_socialwise_data).and_return(false)
        
        result = described_class.enhance_payload(webhook_payload, account)
        socialwise_data = result['socialwise-chatwit']
        
        expect(socialwise_data['metadata']['fallback_used']).to be true
        expect(socialwise_data['metadata']['error']).to include('Validation failed')
      end

      it 'handles validation errors gracefully' do
        # Mock validation to raise error
        allow(described_class).to receive(:validate_socialwise_data).and_raise(StandardError, 'Validation error')
        
        result = described_class.enhance_payload(webhook_payload, account)
        
        # Should return original payload when validation fails
        expect(result).to eq(webhook_payload)
      end

      it 'validates data types correctly' do
        result = described_class.enhance_payload(webhook_payload, account)
        socialwise_data = result['socialwise-chatwit']
        
        # Check integer fields
        expect(socialwise_data['contact_data']['id']).to be_a(Integer)
        expect(socialwise_data['conversation_data']['id']).to be_a(Integer)
        expect(socialwise_data['message_data']['id']).to be_a(Integer)
        expect(socialwise_data['inbox_data']['id']).to be_a(Integer)
        expect(socialwise_data['account_data']['id']).to be_a(Integer)
        
        # Check boolean fields
        expect([TrueClass, FalseClass]).to include(socialwise_data['metadata']['socialwise_active'].class)
        expect([TrueClass, FalseClass]).to include(socialwise_data['metadata']['is_whatsapp_channel'].class)
        expect([TrueClass, FalseClass]).to include(socialwise_data['metadata']['has_whatsapp_api_key'].class)
        
        # Check string fields
        expect(socialwise_data['metadata']['payload_version']).to be_a(String)
        expect(socialwise_data['metadata']['timestamp']).to be_a(String)
        
        # Check hash fields
        expect(socialwise_data['contact_data']['custom_attributes']).to be_a(Hash)
      end

      it 'validates timestamp formats' do
        result = described_class.enhance_payload(webhook_payload, account)
        socialwise_data = result['socialwise-chatwit']
        
        # Check ISO8601 format
        timestamp_fields = [
          socialwise_data['conversation_data']['created_at'],
          socialwise_data['conversation_data']['updated_at'],
          socialwise_data['message_data']['created_at'],
          socialwise_data['metadata']['timestamp']
        ]
        
        timestamp_fields.compact.each do |timestamp|
          expect(timestamp).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
        end
      end
    end
  end
end