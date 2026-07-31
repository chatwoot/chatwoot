require 'rails_helper'

RSpec.describe Channel::TelnyxSms do
  describe '#provider_config' do
    it 'stores provider credentials in the Telnyx SMS config record' do
      channel = create(:channel_telnyx_sms)

      expect(channel.telnyx_sms_config).to have_attributes(
        api_key: 'test-api-key',
        messaging_profile_id: 'test-messaging-profile-id'
      )
      expect(channel.attributes).not_to include('provider_config')
    end

    it 'accepts only the supported provider configuration attributes' do
      channel = build(:channel_telnyx_sms)

      channel.provider_config = {
        api_key: 'updated-api-key',
        messaging_profile_id: 'updated-profile-id',
        unsupported: 'ignored'
      }

      expect(channel.telnyx_sms_config.attributes).to include(
        'api_key' => 'updated-api-key',
        'messaging_profile_id' => 'updated-profile-id'
      )
      expect(channel.telnyx_sms_config).not_to respond_to(:unsupported)
    end
  end

  describe '#send_text_message' do
    let(:channel) { create(:channel_telnyx_sms) }
    let(:response) { instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => { 'id' => 'message-id' } }) }

    it 'sends the message through the Telnyx API' do
      expect(HTTParty).to receive(:post).with(
        'https://api.telnyx.com/v2/messages',
        headers: {
          'Authorization' => 'Bearer test-api-key',
          'Content-Type' => 'application/json'
        },
        body: {
          from: channel.phone_number,
          to: '+15555550123',
          text: 'Hello from Chatwoot',
          messaging_profile_id: 'test-messaging-profile-id'
        }.to_json
      ).and_return(response)

      expect(channel.send_text_message('+15555550123', 'Hello from Chatwoot')).to eq('message-id')
    end
  end
end
