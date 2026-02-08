# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Instagram Channel Validation Integration', type: :integration do
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account, instagram_id: '123456789') }
  let(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: instagram_inbox, contact: contact, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account) }

  before do
    # Mock Instagram token refresh API calls
    stub_request(:get, /graph\.instagram\.com\/refresh_access_token/)
      .to_return(
        status: 200,
        body: { access_token: 'refreshed_token', expires_in: 3600 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    # Mock the access_token method to avoid API calls
    allow_any_instance_of(Channel::Instagram).to receive(:access_token).and_return('valid_access_token_123456789')
  end

  describe 'SocialWise Instagram Response Processor integration' do
    let(:valid_socialwise_data) do
      {
        'message_format' => 'GENERIC_TEMPLATE',
        'payload' => {
          'template_type' => 'generic',
          'elements' => [
            {
              'title' => 'Test Card',
              'subtitle' => 'Test Description',
              'buttons' => [
                {
                  'type' => 'postback',
                  'title' => 'Select',
                  'payload' => 'test_payload'
                }
              ]
            }
          ]
        }
      }
    end

    context 'when Instagram channel is properly configured' do
      before do
        instagram_channel.update!(
          access_token: 'valid_access_token_123456789',
          instagram_id: '123456789',
          expires_at: 1.hour.from_now
        )
      end

      it 'passes validation and processes the message' do
        validator = InstagramChannelValidator.new(message)
        expect(validator.valid_for_rich_messages?).to be true
        expect(validator.errors).to be_empty
      end

      it 'integrates correctly with SocialWise processor' do
        # Mock the Instagram Rich Message Service to avoid actual API calls
        allow(Instagram::RichMessageService).to receive(:new).and_return(double(perform: true))
        
        result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_socialwise_data, message)
        expect(result).to be true
      end
    end

    context 'when Instagram channel has invalid configuration' do
      before do
        instagram_channel.update!(
          access_token: 'valid_access_token_123456789',
          instagram_id: 'invalid_id_format',  # Invalid format (should be numeric)
          expires_at: 1.hour.from_now
        )
      end

      it 'fails validation with appropriate error' do
        validator = InstagramChannelValidator.new(message)
        expect(validator.valid_for_rich_messages?).to be false
        expect(validator.errors).to include(/Instagram ID has invalid format/)
      end

      it 'falls back to text message in SocialWise processor' do
        # Mock the fallback behavior
        expect(Integrations::Socialwise::InstagramResponseProcessor).to receive(:fallback_to_text_message).and_return(true)
        
        result = Integrations::Socialwise::InstagramResponseProcessor.process(valid_socialwise_data, message)
        expect(result).to be true  # Fallback should succeed
      end
    end

    context 'when channel is not Instagram' do
      let(:non_instagram_inbox) { create(:inbox, account: account) }
      let(:non_instagram_conversation) { create(:conversation, inbox: non_instagram_inbox, contact: contact, account: account) }
      let(:non_instagram_message) { create(:message, conversation: non_instagram_conversation, account: account) }

      before do
        # Mock the inbox to return a different channel type
        allow(non_instagram_inbox).to receive(:channel_type).and_return('Channel::WebWidget')
      end

      it 'fails validation for non-Instagram channels' do
        validator = InstagramChannelValidator.new(non_instagram_message)
        expect(validator.valid_for_rich_messages?).to be false
        expect(validator.errors).to include(/Rich messages only supported for Instagram channels/)
      end
    end
  end

  describe 'Validation status reporting' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
    end

    it 'provides detailed validation status' do
      validator = InstagramChannelValidator.new(message)
      validator.valid_for_rich_messages?
      
      status = validator.validation_status
      expect(status).to include(
        valid: true,
        channel_type: 'Channel::Instagram',
        is_instagram: true,
        channel_present: true,
        access_token_present: true,
        instagram_id_present: true,
        channel_expired: false,
        errors: []
      )
    end
  end

  describe 'Compatibility with existing Instagram functionality' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
    end

    it 'does not interfere with existing channel methods' do
      validator = InstagramChannelValidator.new(message)
      
      # Ensure validator doesn't break existing functionality
      expect(instagram_channel.name).to eq('Instagram')
      expect(instagram_channel.instagram_id).to eq('123456789')
      expect(instagram_channel.access_token).to be_present
      
      # Validator should still work
      expect(validator.valid_for_rich_messages?).to be true
    end

    it 'works with existing inbox and message functionality' do
      validator = InstagramChannelValidator.new(message)
      
      expect(message.conversation).to eq(conversation)
      expect(conversation.inbox).to eq(instagram_inbox)
      expect(instagram_inbox.channel).to eq(instagram_channel)
      
      # Validator should still work
      expect(validator.valid_for_rich_messages?).to be true
    end
  end
end