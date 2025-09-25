#!/usr/bin/env ruby

puts "🔍 Comparing Time Picker Formats"
puts "=" * 50

# Apple Sample Format (from 10_send_time_picker_with_user_timezone.py)
apple_sample = {
  "type" => "interactive",
  "interactiveData" => {
    "bid" => "IMESSAGE_EXTENSION_BID",
    "data" => {
      "mspVersion" => "1.0",
      "requestIdentifier" => "request_id",
      "event" => {
        "identifier" => "1",
        "title" => "",
        "timeslots" => [
          {
            "duration" => 3600,
            "startTime" => "2022-07-10T17:00+0000",
            "identifier" => "0"
          }
        ]
      }
    },
    "receivedMessage" => {
      "style" => "icon",
      "title" => "Please pick a time",
      "subtitle" => "This should be 10:00am for GMT-7h users"
    },
    "replyMessage" => {
      "style" => "icon",
      "title" => "Thank you!"
    }
  },
  "sourceId" => "BIZ_ID",
  "destinationId" => "destination_id",
  "v" => 1,
  "id" => "message_id"
}

puts "\n📋 Apple Sample Time Picker Structure:"
puts JSON.pretty_generate(apple_sample)

# Our Current Format
account = Account.first || Account.create!(name: 'Test Account')
channel = Channel::AppleMessagesForBusiness.find_or_create_by(account: account) do |c|
  c.business_id = SecureRandom.uuid
  c.msp_id = 'test-msp-id'
  c.secret = Base64.encode64('test-secret')
  c.certificate = 'test-certificate'
end

conversation = Conversation.find_or_create_by(account: account, inbox: channel.inbox) do |c|
  c.contact = Contact.find_or_create_by(account: account, phone_number: '+1234567890') do |contact|
    contact.name = 'Test Contact'
  end
  c.status = 'open'
end

message = Message.create!(
  account: account,
  inbox: channel.inbox,
  conversation: conversation,
  message_type: 'outgoing',
  content_type: 'apple_time_picker',
  content: "Test Time Picker",
  content_attributes: {
    'event' => {
      'identifier' => '1',
      'title' => '',
      'timeslots' => [
        {
          'duration' => 3600,
          'startTime' => '2022-07-10T17:00+0000',
          'identifier' => '0'
        }
      ]
    },
    'received_title' => 'Please pick a time',
    'received_subtitle' => 'This should be 10:00am for GMT-7h users',
    'reply_title' => 'Thank you!'
  }
)

service = AppleMessagesForBusiness::SendMessageService.new(
  channel: channel,
  destination_id: 'tel:+1234567890',
  message: message
)

our_payload = service.send(:build_apple_msp_payload, SecureRandom.uuid)

puts "\n📋 Our Current Time Picker Structure:"
puts JSON.pretty_generate(our_payload)

puts "\n🔍 Key Differences Analysis:"
puts "-" * 30

# Compare structures
apple_data = apple_sample["interactiveData"]["data"]
our_data = our_payload[:interactiveData][:data]

puts "✅ Apple Sample - data.mspVersion: #{apple_data['mspVersion']}"
puts "✅ Our Format - data.mspVersion: #{our_data[:mspVersion]}"

puts "✅ Apple Sample - data.event.identifier: #{apple_data['event']['identifier']}"
puts "✅ Our Format - data.event.identifier: #{our_data[:event]['identifier']}"

puts "✅ Apple Sample - data.event.title: '#{apple_data['event']['title']}'"
puts "✅ Our Format - data.event.title: '#{our_data[:event]['title']}'"

puts "✅ Apple Sample - data.event.timeslots count: #{apple_data['event']['timeslots'].length}"
puts "✅ Our Format - data.event.timeslots count: #{our_data[:event]['timeslots'].length}"

apple_received = apple_sample["interactiveData"]["receivedMessage"]
our_received = our_payload[:interactiveData][:receivedMessage]

puts "✅ Apple Sample - receivedMessage.style: #{apple_received['style']}"
puts "✅ Our Format - receivedMessage.style: #{our_received[:style]}"

puts "✅ Apple Sample - receivedMessage.title: '#{apple_received['title']}'"
puts "✅ Our Format - receivedMessage.title: '#{our_received[:title]}'"

apple_reply = apple_sample["interactiveData"]["replyMessage"]
our_reply = our_payload[:interactiveData][:replyMessage]

puts "✅ Apple Sample - replyMessage.style: #{apple_reply['style']}"
puts "✅ Our Format - replyMessage.style: #{our_reply[:style]}"

puts "✅ Apple Sample - replyMessage.title: '#{apple_reply['title']}'"
puts "✅ Our Format - replyMessage.title: '#{our_reply[:title]}'"

puts "\n🎯 Conclusion:"
puts "The structures appear to match the Apple sample format!"
puts "If there are still issues, they might be in field types or subtle differences."