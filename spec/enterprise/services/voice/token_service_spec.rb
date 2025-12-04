require 'rails_helper'

describe Voice::TokenService do
  before { allow_any_instance_of(Channel::Voice).to receive(:provision_twilio_on_create).and_return(true) }

  let(:account) { create(:account) }
  let(:user) { create(:user, :administrator, account: account) }
  let(:voice_channel) { create(:channel_voice, account: account) }
  let(:inbox) { voice_channel.inbox }

  it 'returns a token payload with expected keys' do
    fake_token = instance_double(Twilio::JWT::AccessToken, to_jwt: 'jwt-token', add_grant: nil)
    allow(Twilio::JWT::AccessToken).to receive(:new).and_return(fake_token)
    allow_any_instance_of(Twilio::JWT::AccessToken::VoiceGrant).to receive(:outgoing_application_sid=)
    allow_any_instance_of(Twilio::JWT::AccessToken::VoiceGrant).to receive(:outgoing_application_params=)
    allow_any_instance_of(Twilio::JWT::AccessToken::VoiceGrant).to receive(:incoming_allow=)

    payload = described_class.new(inbox: inbox, user: user, account: account).generate

    expect(payload[:token]).to eq('jwt-token')
    expect(payload[:identity]).to include("agent-#{user.id}")
    expect(payload[:inbox_id]).to eq(inbox.id)
    expect(payload[:account_id]).to eq(account.id)
    expect(payload[:voice_enabled]).to be true
    expect(payload[:twiml_endpoint]).to include(voice_channel.phone_number.delete_prefix('+'))
  end
end
