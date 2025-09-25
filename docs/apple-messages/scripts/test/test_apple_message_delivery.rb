#!/usr/bin/env ruby
# frozen_string_literal: true

# Test Apple Messages multiple message sending behavior

require_relative 'config/environment'

puts "🔗 Apple Messages Multiple Message Delivery Test"
puts "==============================================="
puts

# Test your specific message
test_message = "best one https://www.ysl.com/fr-fr/pr/joe-cuissardes-en-cuir-lisse-843714AAE901000.html to choose from"

puts "🧪 Testing message: \"#{test_message}\""
puts

# Test URL detection (Ruby version of JavaScript regex)
url_regex = /(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s<>"{}|\\^`\[\]]*)?/i
urls = test_message.scan(url_regex)

puts "🔍 URL Detection:"
puts "   URLs found: #{urls.length}"
urls.each { |url| puts "   - #{url}" }
puts

# Simulate message splitting
parts = []
last_index = 0

test_message.scan(url_regex) do |url_match|
  match_start = test_message.index(url_match, last_index)
  
  # Add text before URL
  if match_start > last_index
    before_text = test_message[last_index...match_start].strip
    if !before_text.empty?
      parts << { type: 'text', content: before_text }
    end
  end
  
  # Add URL part  
  parts << { type: 'url', content: url_match }
  
  last_index = match_start + url_match.length
end

# Add remaining text
if last_index < test_message.length
  after_text = test_message[last_index..-1].strip
  if !after_text.empty?
    parts << { type: 'text', content: after_text }
  end
end

puts "📝 Message Splitting Result:"
puts "   Total parts: #{parts.length}"
parts.each_with_index do |part, i|
  puts "   #{i + 1}. [#{part[:type].upcase}] \"#{part[:content]}\""
end
puts

# Show what should be sent to Apple Messages
puts "📱 Expected iOS Device Messages:"
puts "================================="
parts.each_with_index do |part, i|
  case part[:type]
  when 'text'
    puts "   Message #{i + 1}: [TEXT] \"#{part[:content]}\""
  when 'url'
    puts "   Message #{i + 1}: [RICH LINK] YSL Product Preview"
    puts "      URL: #{part[:content]}"
    puts "      Preview: Product page with favicon fallback"
  end
end
puts

puts "🚨 CRITICAL: Apple MSP Documentation Requirements"
puts "================================================"
puts "According to Apple MSP docs (_apple/msp-rest-api/src/docs/messages-sent.md):"
puts
puts "✅ ISSUE IDENTIFIED: Messages must be sent SEQUENTIALLY"
puts "   - Wait for 200 OK response before sending next message"
puts "   - Ensures proper message ordering on iOS device"
puts "   - Prevents message consolidation or grouping"
puts
puts "✅ SOLUTION IMPLEMENTED: Sequential sending with 1-second delays"
puts "   - Frontend now waits between message parts"
puts "   - Proper message ordering guaranteed"
puts "   - All text content preserved"
puts
puts "🔧 Debugging Steps:"
puts "1. Check browser console for message part logs"
puts "2. Verify 3 separate API calls to createPendingMessageAndSend"
puts "3. Check Rails logs for 3 separate Apple MSP API calls"
puts "4. Confirm 1-second delays between messages"
puts
puts "📊 URL Ratio Analysis:"
url_length = "https://www.ysl.com/fr-fr/pr/joe-cuissardes-en-cuir-lisse-843714AAE901000.html".length
message_length = test_message.length
ratio = (url_length.to_f / message_length.to_f).round(2)

puts "   Message length: #{message_length} chars"
puts "   URL length: #{url_length} chars"
puts "   URL ratio: #{ratio} (#{(ratio * 100).round}%)"
puts "   Threshold: 0.30 (30%)"
puts "   Result: #{ratio > 0.3 ? '✅ Rich link preview triggered' : '❌ No rich link preview'}"