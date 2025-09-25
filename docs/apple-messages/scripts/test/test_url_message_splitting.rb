#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for Apple Messages text + URL message splitting

puts "🔗 Testing Apple Messages Text + URL Message Processing"
puts "======================================================="
puts

# Test the URL regex and message splitting logic
test_cases = [
  "best one https://www.ysl.com/fr-fr/pr/joe-cuissardes-en-cuir-lisse-843714AAE901000.html to choose from",
  "Check out this link: https://github.com/chatwoot/chatwoot",
  "https://apple.com is amazing",
  "Visit https://google.com for search and https://github.com for code",
  "No URLs in this message",
  "Multiple sites: https://example.com and https://test.com work great!"
]

# Simulate the JavaScript URL regex in Ruby
url_regex = /(?:https?:\/\/)?(?:www\.)?[a-zA-Z0-9-]+\.[a-zA-Z]{2,}(?:\/[^\s<>"{}|\\^`[\]]*)?/i

test_cases.each_with_index do |message, index|
  puts "#{index + 1}. Testing: \"#{message}\""
  
  # Find URLs in the message
  urls = message.scan(url_regex)
  puts "   🔍 URLs detected: #{urls.length}"
  urls.each { |url| puts "      - #{url}" }
  
  # Simulate message splitting logic  
  parts = []
  last_index = 0
  
  message.scan(url_regex) do |url_match|
    match_start = message.index(url_match, last_index)
    
    # Add text before URL
    if match_start > last_index
      before_text = message[last_index...match_start].strip
      if !before_text.empty?
        parts << { type: 'text', content: before_text }
      end
    end
    
    # Add URL part  
    parts << { type: 'url', content: url_match }
    
    last_index = match_start + url_match.length
  end
  
  # Add remaining text
  if last_index < message.length
    after_text = message[last_index..-1].strip
    if !after_text.empty?
      parts << { type: 'text', content: after_text }
    end
  end
  
  # If no URLs found, add whole message as text
  if parts.empty?
    parts << { type: 'text', content: message }
  end
  
  puts "   📝 Message parts: #{parts.length}"
  parts.each_with_index do |part, i|
    puts "      #{i + 1}. [#{part[:type].upcase}] \"#{part[:content]}\""
  end
  
  puts "   💬 Would send: #{parts.length} separate message(s)"
  puts "   " + "="*60
  puts
end

puts "🎯 Expected Results for Your Example:"
puts "======================================"
puts "Message: \"best one https://www.ysl.com/fr-fr/pr/joe-cuissardes-en-cuir-lisse-843714AAE901000.html to choose from\""
puts
puts "Should split into:"
puts "  1. [TEXT] \"best one\""
puts "  2. [RICH_LINK] \"https://www.ysl.com/fr-fr/pr/joe-cuissardes-en-cuir-lisse-843714AAE901000.html\""  
puts "  3. [TEXT] \"to choose from\""
puts
puts "iOS device should receive:"
puts "  📱 Message 1: \"best one\""
puts "  📱 Message 2: Rich link preview with YSL product info"
puts "  📱 Message 3: \"to choose from\""
puts
puts "✅ This preserves all content while providing rich link preview!"