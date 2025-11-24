#!/usr/bin/env ruby
# Demo script to showcase all three implemented features
# Run with: bin/rails runner demo_features.rb

puts '=' * 80
puts 'CHATWOOT ENHANCEMENT PROJECT - FEATURE DEMONSTRATION'
puts '=' * 80
puts ''

# Get the first account and contact
account = Account.first
contact = Contact.first

unless account && contact
  puts '⚠️  No account or contact found. Please create some test data first.'
  exit
end

puts "📊 Using Account: #{account.name} (ID: #{account.id})"
puts "👤 Using Contact: #{contact.name || contact.email} (ID: #{contact.id})"
puts ''

# ============================================================================
# FEATURE 1: SMART CONVERSATION PRIORITY SCORING
# ============================================================================
puts '=' * 80
puts 'FEATURE 1: SMART CONVERSATION PRIORITY SCORING SYSTEM'
puts '=' * 80
puts ''

# Get or create a conversation
conversation = contact.conversations.first || begin
  inbox = account.inboxes.first
  contact_inbox = contact.contact_inboxes.find_or_create_by!(inbox: inbox)
  Conversation.create!(
    account: account,
    inbox: inbox,
    contact: contact,
    contact_inbox: contact_inbox,
    status: :open
  )
end

puts "🔍 Analyzing Conversation ##{conversation.display_id}..."
puts ''

# Calculate priority
service = ConversationPriorityService.new(conversation)
service.calculate_and_update!
conversation.reload

puts '✅ Priority Calculation Complete!'
puts ''
puts "   Priority Score: #{conversation.priority_score}/100"
puts "   Priority Level: #{conversation.priority_level.upcase}"
puts '   Factors:'
conversation.priority_factors.each do |key, value|
  puts "     - #{key.titleize}: #{value}"
end
puts ''

# Show priority distribution
puts '📈 Priority Distribution Across All Conversations:'
Conversation.group(:priority_level).count.each do |level, count|
  level_name = Conversation.priority_levels.key(level)
  puts "   #{level_name.to_s.titleize}: #{count} conversations"
end
puts ''

# ============================================================================
# FEATURE 2: ADVANCED CUSTOMER INSIGHTS DASHBOARD
# ============================================================================
puts '=' * 80
puts 'FEATURE 2: ADVANCED CUSTOMER INSIGHTS DASHBOARD'
puts '=' * 80
puts ''

puts "🔍 Generating insights for #{contact.name || contact.email}..."
puts ''

insights = CustomerInsightsService.new(contact).generate_insights

# Sentiment Analysis
puts '😊 SENTIMENT ANALYSIS:'
if insights[:sentiment_analysis][:available]
  sentiment = insights[:sentiment_analysis]
  puts "   Recent Sentiment: #{sentiment[:recent_sentiment].upcase}"
  puts '   Overall Distribution:'
  sentiment[:overall_distribution].each do |type, count|
    puts "     - #{type.to_s.capitalize}: #{count} messages"
  end
else
  puts '   No sentiment data available'
end
puts ''

# CSAT Metrics
puts '⭐ CSAT METRICS:'
if insights[:csat_metrics][:available]
  csat = insights[:csat_metrics]
  puts "   Average Rating: #{csat[:average_rating]}/5.0"
  puts "   Total Responses: #{csat[:total_responses]}"
  puts "   Trend: #{csat[:trend].upcase}"
else
  puts '   No CSAT data available'
end
puts ''

# Engagement Metrics
puts '💬 ENGAGEMENT METRICS:'
if insights[:engagement_metrics][:available]
  engagement = insights[:engagement_metrics]
  puts "   Total Conversations: #{engagement[:total_conversations]}"
  puts "   Open Conversations: #{engagement[:open_conversations]}"
  puts "   Resolved Conversations: #{engagement[:resolved_conversations]}"
  puts "   Average Messages per Conversation: #{engagement[:avg_messages_per_conversation]}"
  puts "   Response Rate: #{engagement[:response_rate]}%"
  puts "   Most Active Day: #{engagement[:most_active_day]}"
else
  puts '   No engagement data available'
end
puts ''

# Response Time Analysis
puts '⏱️  RESPONSE TIME ANALYSIS:'
if insights[:response_time_metrics][:available]
  response_time = insights[:response_time_metrics]
  puts "   Average First Response: #{response_time[:average_first_response_time_minutes].round(1)} minutes"
  puts "   Fastest Response: #{response_time[:fastest_response_minutes].round(1)} minutes"
  puts "   Slowest Response: #{response_time[:slowest_response_minutes].round(1)} minutes"
else
  puts '   No response time data available'
end
puts ''

# ============================================================================
# FEATURE 3: INTELLIGENT AUTO-RESPONSE SUGGESTIONS
# ============================================================================
puts '=' * 80
puts 'FEATURE 3: INTELLIGENT AUTO-RESPONSE SUGGESTIONS'
puts '=' * 80
puts ''

# Check if we have canned responses
canned_count = account.canned_responses.count
puts "📝 Found #{canned_count} canned responses in account"
puts ''

if canned_count > 0
  # Check embeddings
  with_embeddings = account.canned_responses.where.not(embedding: nil).count
  puts "🤖 Canned responses with embeddings: #{with_embeddings}/#{canned_count}"

  if with_embeddings == 0
    puts '⚠️  No embeddings found. Generating embeddings...'
    puts '   (This requires OpenAI API key to be configured)'
    puts ''
    puts '   To generate embeddings, run:'
    puts '   bin/rails runner "CannedResponse.find_each { |r| CannedResponseEmbeddingJob.perform_now(r) }"'
  else
    puts ''
    puts "🔍 Generating response suggestions for conversation ##{conversation.display_id}..."
    puts ''

    begin
      suggestions = CannedResponseSuggestionService.new(conversation).suggest_responses(limit: 5)

      if suggestions.any?
        puts "✅ Found #{suggestions.size} suggested responses:"
        puts ''
        suggestions.each_with_index do |suggestion, index|
          puts "   #{index + 1}. [#{suggestion[:short_code]}] (Similarity: #{(suggestion[:similarity_score] * 100).round(1)}%)"
          puts "      #{suggestion[:content][0..80]}#{'...' if suggestion[:content].length > 80}"
          puts ''
        end
      else
        puts '   No suggestions found for this conversation context'
      end
    rescue StandardError => e
      puts "   ⚠️  Error generating suggestions: #{e.message}"
    end
  end
else
  puts '⚠️  No canned responses found. Create some canned responses first:'
  puts "   CannedResponse.create!(account: account, short_code: 'welcome', content: 'Welcome to our support!')"
end
puts ''

# ============================================================================
# SUMMARY
# ============================================================================
puts '=' * 80
puts 'DEMONSTRATION COMPLETE'
puts '=' * 80
puts ''
puts '✨ All three features have been successfully demonstrated!'
puts ''
puts '📚 For more details, see PROJECT_FEATURES_SUMMARY.md'
puts ''
