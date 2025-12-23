require 'rspec/matchers'
require 'twilio-ruby'
require './lib/twilio-ruby/credential/client_credential_provider'

describe 'Cluster Test' do
  before(:each) do
    @client_secret = ENV['TWILIO_ORGS_CLIENT_SECRET']
    @client_id = ENV['TWILIO_ORGS_CLIENT_ID']
    @org_sid = ENV['TWILIO_ORG_SID']
    @user_sid = ENV['TWILIO_USER_SID']
    @account_sid = ENV['TWILIO_ORGS_ACCOUNT_SID']
    @credential = Twilio::REST::ClientCredentialProvider.new(@client_id, @client_secret)
    @client = Twilio::REST::Client.new.credential_provider(@credential)
  end

  it 'can list accounts' do
    response = @client.preview_iam.organizations(@org_sid).accounts.list
    expect(response).to_not be_nil
  end

  it 'can fetch specific account' do
    response = @client.preview_iam.organizations(@org_sid).accounts(@account_sid).fetch
    expect(response).to_not be_nil
  end

  it 'can access role assignments list' do
    response = @client.preview_iam.organizations(@org_sid).role_assignments.list(scope: @account_sid)
    expect(response).to_not be_nil
  end

  it 'can get user list' do
    response = @client.preview_iam.organizations(@org_sid).users.list
    expect(response).to_not be_nil
  end

  it 'can get single user' do
    response = @client.preview_iam.organizations(@org_sid).users(@user_sid).fetch
    expect(response).to_not be_nil
  end
end
