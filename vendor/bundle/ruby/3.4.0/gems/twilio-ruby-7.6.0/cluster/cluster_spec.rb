require 'rspec/matchers'
require 'twilio-ruby'

describe 'Cluster Test' do
  before(:each) do
    @account_sid = ENV['TWILIO_ACCOUNT_SID']
    @secret = ENV['TWILIO_API_SECRET']
    @api_key = ENV['TWILIO_API_KEY']
    @to_number = ENV['TWILIO_TO_NUMBER']
    @from_number = ENV['TWILIO_FROM_NUMBER']
    @client = Twilio::REST::Client.new @api_key, @secret, @account_sid
  end

  it 'can send a text' do
    message = @client.messages.create(
      to: @to_number,
      from: @from_number,
      body: 'Cluster test message from twilio-ruby'
    )
    expect(message).to_not eq(nil)
    expect(message.body.include?('Cluster test message from twilio-ruby')).to eq(true)
    expect(message.from).to eq(@from_number)
    expect(message.to).to eq(@to_number)
  end

  it 'can list numbers' do
    phone_numbers = @client.incoming_phone_numbers.list
    expect(phone_numbers).to_not eq(nil)
    expect(phone_numbers).to_not match_array([])
  end

  it 'list a number' do
    phone_numbers = @client.incoming_phone_numbers.list(phone_number: @from_number)
    expect(phone_numbers).to_not eq(nil)
    expect(phone_numbers[0].phone_number).to eq(@from_number)
  end

  it 'allows special characters for friendly and identity name' do
    service = @client.chat.v2.services.create(friendly_name: 'service|friendly&name')
    expect(service).to_not eq(nil)

    user = @client.chat.v2.services(service.sid).users.create(identity: 'user|identity&string')
    expect(user).to_not eq(nil)

    is_user_deleted = @client.chat.v2.services(service.sid).users(user.sid).delete
    expect(is_user_deleted).to eq(true)

    is_service_deleted = @client.chat.v2.services(service.sid).delete
    expect(is_service_deleted).to eq(true)
  end

  it 'test list params' do
    sink_configuration = { 'destination' => 'http://example.org/webhook', 'method' => 'post',
                           'batch_events' => false }
    types = [{ 'type' => 'com.twilio.messaging.message.delivered' },
             { 'type' => 'com.twilio.messaging.message.sent' }]

    sink = @client.events.v1.sinks.create(
      description: 'test sink ruby',
      sink_configuration: sink_configuration,
      sink_type: 'webhook'
    )
    expect(sink).to_not eq(nil)

    subscription = @client.events.v1.subscriptions.create(
      description: 'test subscription ruby',
      types: types,
      sink_sid: sink.sid
    )
    expect(subscription).to_not eq(nil)

    expect(@client.events.v1.subscriptions(subscription.sid).delete).to eq(true)
    expect(@client.events.v1.sinks(sink.sid).delete).to eq(true)
  end
end
