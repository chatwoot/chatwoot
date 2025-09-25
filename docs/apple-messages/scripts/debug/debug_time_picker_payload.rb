#!/usr/bin/env ruby

puts "🔧 Debugging Time Picker Payload Structure"
puts "==========================================="

# Create a time picker message with the corrected structure
conversation = Conversation.find(4)

time_message = Message.create!(
  content: 'Debug Time Picker',
  content_type: 'apple_time_picker',
  content_attributes: {
    'event' => {
      'title' => 'Debug Appointment',
      'description' => 'Testing time slots',
      'timeslots' => [
        {
          'startTime' => '2025-12-16T10:00+0000',
          'duration' => 3600
        },
        {
          'startTime' => '2025-12-16T14:00+0000', 
          'duration' => 3600
        }
      ]
    },
    'received_title' => 'Book Debug Appointment',
    'received_subtitle' => 'Available debug slots',
    'received_style' => 'icon',
    'reply_title' => 'Debug Confirmed',
    'reply_style' => 'icon'
  },
  account: conversation.account,
  inbox: conversation.inbox,
  conversation: conversation,
  message_type: 'outgoing'
)

puts "✅ Debug Time Picker created: Message ID #{time_message.id}"

# Examine the stored content_attributes
puts "\n🔍 Stored Content Attributes:"
puts JSON.pretty_generate(time_message.content_attributes)

# Generate the Apple MSP payload
service = AppleMessagesForBusiness::SendMessageService.new(
  channel: conversation.inbox.channel,
  destination_id: 'debug_destination',
  message: time_message
)

payload = service.send(:build_apple_msp_payload, SecureRandom.uuid)

puts "\n📱 Generated Apple MSP Payload:"
puts JSON.pretty_generate(payload)

puts "\n🔍 Time Picker Specific Analysis:"
puts "================================="

event_data = payload[:interactiveData][:data][:event]
puts "• Event present: #{event_data.present?}"
puts "• Event keys: #{event_data&.keys}"
puts "• Event title: #{event_data&.dig('title')}"
puts "• Timeslots present: #{event_data&.dig('timeslots').present?}"
puts "• Timeslots count: #{event_data&.dig('timeslots')&.length || 0}"

if event_data&.dig('timeslots')
  event_data['timeslots'].each_with_index do |slot, index|
    puts "  Slot #{index + 1}:"
    puts "    • startTime: #{slot['startTime']}"
    puts "    • duration: #{slot['duration']}"
    puts "    • identifier: #{slot['identifier']}"
  end
end

puts "\n📋 Apple Sample Comparison:"
puts "============================"

apple_sample = {
  "type" => "interactive",
  "interactiveData" => {
    "bid" => "com.apple.messages.MSMessageExtensionBalloonPlugin:0000000000:com.apple.icloud.apps.messages.business.extension",
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
  }
}

puts "Apple Sample Event Structure:"
puts JSON.pretty_generate(apple_sample["interactiveData"]["data"]["event"])

puts "\nOur Generated Event Structure:"
puts JSON.pretty_generate(event_data)

puts "\n🎯 Key Differences Analysis:"
puts "============================="

apple_event = apple_sample["interactiveData"]["data"]["event"]
our_event = event_data

puts "• Event identifier - Apple: #{apple_event['identifier']}, Ours: #{our_event&.dig('identifier')}"
puts "• Event title - Apple: '#{apple_event['title']}', Ours: '#{our_event&.dig('title')}'"
puts "• Timeslots structure match: #{apple_event['timeslots'].class == our_event&.dig('timeslots')&.class}"

if our_event&.dig('timeslots')
  apple_slot = apple_event['timeslots'][0]
  our_slot = our_event['timeslots'][0]
  
  puts "\nFirst Timeslot Comparison:"
  puts "• Duration - Apple: #{apple_slot['duration']}, Ours: #{our_slot['duration']}"
  puts "• StartTime - Apple: #{apple_slot['startTime']}, Ours: #{our_slot['startTime']}"
  puts "• Identifier - Apple: #{apple_slot['identifier']}, Ours: #{our_slot['identifier']}"
end

puts "\n💡 Debug Analysis Complete!"