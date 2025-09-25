puts 'Checking Apple Messages:'
Message.where(content_type: ['apple_list_picker', 'apple_quick_reply', 'apple_time_picker']).each do |m|
  puts "Message #{m.id}: #{m.content_type} in conversation #{m.conversation_id}"
  puts "  Content: #{m.content_attributes}"
  puts "  ---"
end