require 'twilio-ruby'
require 'twilio-ruby/credential/client_credential_provider'

credential_provider = Twilio::REST::ClientCredentialProvider.new(ENV['CLIENT_ID'], ENV['CLIENT_SECRET'])
# passing account sid is not mandatory
client = Twilio::REST::Client.new(ENV['ACCOUNT_SID']).credential_provider(credential_provider)

# send messages
client.messages.create(
  from: ENV['TWILIO_PHONE_NUMBER'],
  to: ENV['PHONE_NUMBER'],
  body: 'Hello from Ruby!'
)
