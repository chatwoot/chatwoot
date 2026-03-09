# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InstagramChannelValidator, type: :validator do
  before do
    # Mock Instagram token refresh API calls
    stub_request(:get, /graph\.instagram\.com\/refresh_access_token/)
      .to_return(
        status: 200,
        body: { access_token: 'refreshed_token', expires_in: 3600 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    
    # Mock WhatsApp provider validation calls
    stub_request(:post, /waba\.360dialog\.io/)
      .to_return(status: 200, body: '{}', headers: {})
      
    # Mock the access_token method to avoid API calls
    allow_any_instance_of(Channel::Instagram).to receive(:access_token).and_return('valid_access_token_123456789')
  end
  let(:account) { create(:account) }
  let(:instagram_channel) { create(:channel_instagram, account: account) }
  let(:instagram_inbox) { create(:inbox, channel: instagram_channel, account: account) }
  let(:contact) { create(:contact, account: account) }
  let(:conversation) { create(:conversation, inbox: instagram_inbox, contact: contact, account: account) }
  let(:message) { create(:message, conversation: conversation, account: account) }
  let(:validator) { described_class.new(message) }

  describe '#valid_for_rich_messages?' do
    context 'when all validations pass' do
      before do
        # Ensure channel has valid configuration
        instagram_channel.update!(
          access_token: 'valid_access_token_123456789',
          instagram_id: '123456789',
          expires_at: 1.hour.from_now
        )
      end

      it 'returns true' do
        expect(validator.valid_for_rich_messages?).to be true
      end

      it 'has no errors' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to be_empty
      end

      it 'logs successful validation' do
        allow(Rails.logger).to receive(:info)
        expect(validator.valid_for_rich_messages?).to be true
        expect(Rails.logger).to have_received(:info).with(/INSTAGRAM CHANNEL VALIDATION PASSED/)
      end
    end

    context 'when channel is not Instagram' do
      before do
        # Mock the inbox to return a different channel type
        allow(instagram_inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Rich messages only supported for Instagram channels/)
      end

      it 'logs validation failure' do
        expect(Rails.logger).to receive(:warn).with(/Rich messages only supported for Instagram channels/)
        validator.valid_for_rich_messages?
      end
    end

    context 'when channel configuration is missing' do
      before do
        allow(instagram_inbox).to receive(:channel).and_return(nil)
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Instagram channel configuration not found/)
      end
    end

    context 'when access token is missing' do
      before do
        instagram_channel.update!(access_token: nil)
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Instagram access token not available/)
      end
    end

    context 'when access token is too short' do
      before do
        instagram_channel.update!(access_token: 'short')
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Instagram access token appears to be invalid/)
      end
    end

    context 'when Instagram ID is missing' do
      before do
        instagram_channel.update!(instagram_id: nil)
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Instagram ID not configured/)
      end
    end

    context 'when Instagram ID has invalid format' do
      before do
        instagram_channel.update!(instagram_id: 'invalid_id_format')
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Instagram ID has invalid format/)
      end
    end

    context 'when channel token is expired' do
      before do
        instagram_channel.update!(
          access_token: 'valid_access_token_123456789',
          instagram_id: '123456789',
          expires_at: 1.hour.ago
        )
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Instagram channel access token expired/)
      end
    end



    context 'when access token retrieval fails' do
      before do
        allow(instagram_channel).to receive(:access_token).and_raise(StandardError.new('Token refresh failed'))
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds appropriate error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Failed to retrieve Instagram access token/)
      end
    end

    context 'when validation raises an exception' do
      before do
        allow(validator).to receive(:validate_instagram_channel_type).and_raise(StandardError.new('Unexpected error'))
      end

      it 'returns false' do
        expect(validator.valid_for_rich_messages?).to be false
      end

      it 'adds system error' do
        validator.valid_for_rich_messages?
        expect(validator.errors).to include(/Validation failed due to system error/)
      end

      it 'logs the exception' do
        expect(Rails.logger).to receive(:error).with(/Validation failed with exception/)
        validator.valid_for_rich_messages?
      end
    end
  end

  describe '#compatible_channel?' do
    context 'when channel is Instagram' do
      it 'returns true' do
        expect(validator.compatible_channel?).to be true
      end
    end

    context 'when channel is not Instagram' do
      before do
        # Mock the inbox to return a different channel type
        allow(instagram_inbox).to receive(:channel_type).and_return('Channel::Whatsapp')
      end

      it 'returns false' do
        expect(validator.compatible_channel?).to be false
      end
    end
  end

  describe '#error_messages' do
    before do
      validator.instance_variable_set(:@errors, ['Error 1', 'Error 2', 'Error 3'])
    end

    it 'returns formatted error messages' do
      expect(validator.error_messages).to eq('Error 1; Error 2; Error 3')
    end
  end

  describe '#validation_status' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
      validator.valid_for_rich_messages?
    end

    it 'returns detailed validation status' do
      status = validator.validation_status
      
      expect(status).to include(
        valid: true,
        channel_type: 'Channel::Instagram',
        is_instagram: true,
        channel_present: true,
        access_token_present: true,
        instagram_id_present: true,
        channel_expired: false,
        inbox_active: true,
        errors: []
      )
    end
  end

  describe '#test_api_connectivity' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
    end

    context 'when API call succeeds' do
      before do
        stub_request(:get, "https://graph.instagram.com/v22.0/123456789")
          .with(query: { fields: 'id,username', access_token: 'valid_access_token_123456789' })
          .to_return(
            status: 200,
            body: { id: '123456789', username: 'test_account' }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns true' do
        expect(validator.test_api_connectivity).to be true
      end

      it 'logs successful connectivity test' do
        expect(Rails.logger).to receive(:info).with(/API connectivity test passed/)
        validator.test_api_connectivity
      end
    end

    context 'when API call fails with error response' do
      before do
        stub_request(:get, "https://graph.instagram.com/v22.0/123456789")
          .with(query: { fields: 'id,username', access_token: 'valid_access_token_123456789' })
          .to_return(
            status: 400,
            body: { error: { message: 'Invalid access token', code: 190 } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns false' do
        expect(validator.test_api_connectivity).to be false
      end

      it 'adds appropriate error' do
        validator.test_api_connectivity
        expect(validator.errors).to include(/Instagram API connectivity test failed/)
      end
    end

    context 'when API call raises an exception' do
      before do
        stub_request(:get, "https://graph.instagram.com/v22.0/123456789")
          .to_raise(Net::OpenTimeout.new('Request timeout'))
      end

      it 'returns false' do
        expect(validator.test_api_connectivity).to be false
      end

      it 'adds appropriate error' do
        validator.test_api_connectivity
        expect(validator.errors).to include(/Instagram API connectivity test failed with exception/)
      end
    end
  end

  describe 'logging behavior' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
    end

    it 'logs validation start' do
      expect(Rails.logger).to receive(:info).with(/STARTING INSTAGRAM CHANNEL VALIDATION/)
      validator.valid_for_rich_messages?
    end

    it 'logs validation completion with timing' do
      expect(Rails.logger).to receive(:info).with(/Validation time: \d+\.\d+ms/)
      validator.valid_for_rich_messages?
    end

    it 'logs detailed message and conversation information' do
      expect(Rails.logger).to receive(:info).with(/Message ID: #{message.id}, Conversation ID: #{conversation.id}/)
      validator.valid_for_rich_messages?
    end

    it 'logs account and inbox information' do
      expect(Rails.logger).to receive(:info).with(/Account ID: #{account.id}, Inbox ID: #{instagram_inbox.id}/)
      validator.valid_for_rich_messages?
    end
  end

  describe 'performance' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
    end

    it 'completes validation within reasonable time' do
      start_time = Time.current
      validator.valid_for_rich_messages?
      end_time = Time.current
      
      duration = (end_time - start_time) * 1000 # Convert to milliseconds
      expect(duration).to be < 100 # Should complete within 100ms
    end
  end



  describe 'integration with existing Instagram functionality' do
    before do
      instagram_channel.update!(
        access_token: 'valid_access_token_123456789',
        instagram_id: '123456789',
        expires_at: 1.hour.from_now
      )
    end

    it 'does not interfere with existing channel methods' do
      # Ensure validator doesn't break existing functionality
      expect(instagram_channel.name).to eq('Instagram')
      expect(instagram_channel.instagram_id).to eq('123456789')
      expect(instagram_channel.access_token).to be_present
    end

    it 'works with existing inbox functionality' do
      expect(instagram_inbox.channel).to eq(instagram_channel)
      expect(instagram_inbox.channel_type).to eq('Channel::Instagram')
    end

    it 'works with existing message and conversation functionality' do
      expect(message.conversation).to eq(conversation)
      expect(conversation.inbox).to eq(instagram_inbox)
      expect(conversation.account).to eq(account)
    end
  end
end