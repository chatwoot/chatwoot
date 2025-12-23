require 'rspec/matchers'
require 'twilio-ruby'
require './lib/twilio-ruby/credential/client_credential_provider'

describe 'Cluster Test' do
  before(:each) do
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @client_secret = ENV['TWILIO_CLIENT_SECRET']
    @client_id = ENV['TWILIO_CLIENT_ID']
    @message_sid = ENV['TWILIO_MESSAGE_SID']
    @credential = Twilio::REST::ClientCredentialProvider.new(@client_id, @client_secret)
    @client = Twilio::REST::Client.new(@account_sid).credential_provider(@credential)
  end

  it 'can fetch a message' do
    response = @client.messages(@message_sid).fetch
    expect(response).to_not be_nil
  end
end
