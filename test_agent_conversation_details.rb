# Test script for agent conversation-level details with metrics
# Usage: rails runner test_agent_conversation_details.rb
# This script reuses methods from WeeklyAgentLevelReportJob
#
# METRICS CALCULATION EXPLAINED:
# ===============================================================================
#
# 1. FIRST RESPONSE TIME
#    - Source: reporting_events table with name='first_response'
#    - Calculation: Time from when conversation was assigned to agent until
#      agent's first reply to the customer
#    - Stored as: event.value (in seconds)
#    - Not adjusted for pending/snoozed time (this is intentional as it measures
#      actual time to first response)
#
# 2. RESOLUTION TIME (ORIGINAL)
#    - Source: reporting_events table with name='conversation_resolved'
#    - Calculation: Total time from when conversation was assigned to agent
#      until it was resolved
#    - Stored as: event.value (in seconds)
#    - Includes: All time including pending/snoozed periods
#
# 3. RESOLUTION TIME (ADJUSTED)
#    - Calculation: Original Resolution Time - Pending/Snoozed Time
#    - Purpose: Shows actual time agent spent working on the conversation,
#      excluding time when conversation was waiting or snoozed
#    - Formula: MAX(resolution_time - pending_snoozed_time, 0)
#
# 4. AVERAGE RESPONSE TIME (ORIGINAL)
#    - Source: reporting_events table with name='reply_time'
#    - Calculation: Average of all reply times for this conversation
#    - Each reply_time event: Time between customer message and agent's response
#    - Includes: All time including pending/snoozed periods
#
# 5. AVERAGE RESPONSE TIME (ADJUSTED)
#    - Calculation: Original Avg Response Time - (Pending/Snoozed Time / Reply Count)
#    - Purpose: Shows actual response time excluding waiting periods
#    - Formula: MAX(avg_response_time - (pending_snoozed_time / reply_count), 0)
#
# 6. PENDING/SNOOZED TIME
#    - Source: conversation_statuses table
#    - Calculation: Total time conversation spent in 'pending' or 'snoozed' status
#    - Method: Tracks status transitions and calculates duration between:
#      * Status changes to 'pending' → until status changes to 'open' or 'resolved'
#      * Status changes to 'snoozed' → until status changes to 'open' or 'resolved'
#    - If still pending/snoozed: Includes time up to current moment
#    - Logic: See WeeklyAgentLevelReportJob#calculate_pending_snoozed_time (lines 293-334)
#
# DATA SOURCES:
# - reporting_events: Stores time-based metrics (FRT, resolution, response times)
# - conversation_statuses: Tracks conversation status changes over time
# - conversations: Core conversation data (status, timestamps, display_id)
#
# NOTE: All times are in seconds and formatted as "Xh Ym Zs" in the CSV output
# ===============================================================================

require 'csv'
require 'fileutils'

puts '=' * 80
puts 'Agent Conversation Details Report'
puts '=' * 80

# Configuration
account_id = 702
agent_id = 4952 # CHANGE THIS to the specific agent ID you want
range = {
  since: Time.zone.parse('2025-09-01').beginning_of_day,
  until: Time.zone.parse('2025-09-30').end_of_day
}

start_date = range[:since].strftime('%Y-%m-%d')
end_date = range[:until].strftime('%Y-%m-%d')
timestamp = Time.current.strftime('%Y%m%d_%H%M%S')

puts "\nConfiguration:"
puts "  Account ID: #{account_id}"
puts "  Agent ID: #{agent_id}"
puts "  Date Range: #{start_date} to #{end_date}"

# Find account and agent
account = Account.find(account_id)
agent = account.users.find(agent_id)

puts "  Agent Name: #{agent.name}"
puts "  Agent Email: #{agent.email}"
puts "\nGenerating report...\n"

# Instantiate the job to reuse its helper methods
job = WeeklyAgentLevelReportJob.new

# Get all conversations for this agent within the date range
conversation_ids = account.reporting_events
                          .where(user_id: agent_id)
                          .where(created_at: range[:since]..range[:until])
                          .where(name: %w[first_response conversation_resolved reply_time])
                          .distinct
                          .pluck(:conversation_id)
                          .uniq

puts "Found #{conversation_ids.length} conversations for agent #{agent.name}\n"

conversations_data = []

conversation_ids.each_with_index do |conversation_id, index| # rubocop:disable Metrics/BlockLength
  conversation = account.conversations.find_by(id: conversation_id)
  next unless conversation

  inbox = conversation.inbox

  # Get reporting events for this conversation
  frt_event = account.reporting_events
                     .where(name: 'first_response', user_id: agent_id, conversation_id: conversation_id)
                     .where(created_at: range[:since]..range[:until])
                     .first

  resolution_event = account.reporting_events
                            .where(name: 'conversation_resolved', user_id: agent_id, conversation_id: conversation_id)
                            .where(created_at: range[:since]..range[:until])
                            .first

  response_events = account.reporting_events
                           .where(name: 'reply_time', user_id: agent_id, conversation_id: conversation_id)
                           .where(created_at: range[:since]..range[:until])

  # Get raw metric values
  first_response_time = frt_event&.value || 0
  resolution_time = resolution_event&.value || 0
  avg_response_time = response_events.average(:value)&.to_f || 0

  # Use job's method to calculate pending/snoozed time
  pending_snoozed_time = job.send(:calculate_pending_snoozed_time, account, conversation_id)

  # Adjust times (exclude pending/snoozed)
  resolution_time_adjusted = [resolution_time - pending_snoozed_time, 0].max
  avg_response_time_adjusted = if response_events.count.positive?
                                 [avg_response_time - (pending_snoozed_time / response_events.count), 0].max
                               else
                                 0
                               end

  # Generate conversation link
  conversation_link = "https://chat.bitespeed.co/app/accounts/#{account_id}/conversations/#{conversation.display_id}"

  conversations_data << {
    conversation_id: conversation_id,
    conversation_link: conversation_link,
    inbox_name: inbox.name,
    channel_type: inbox.channel_type,
    status: conversation.status,
    created_at: conversation.created_at,
    resolved_at: resolution_event&.created_at,
    first_response_time: first_response_time,
    resolution_time: resolution_time,
    resolution_time_adjusted: resolution_time_adjusted,
    avg_response_time: avg_response_time,
    avg_response_time_adjusted: avg_response_time_adjusted,
    pending_snoozed_time: pending_snoozed_time
  }

  print "\rProcessed #{index + 1}/#{conversation_ids.length} conversations..." if ((index + 1) % 10).zero?
rescue StandardError => e
  puts "\n  ⚠️  Error processing conversation #{conversation_id}: #{e.message}"
end

puts "\n\n✅ Report generated successfully!"
puts "Total conversations: #{conversations_data.length}"

# Generate CSV
if conversations_data.any?
  file_name = "agent_conversation_details_#{agent_id}_#{timestamp}.csv"

  CSV.open(file_name, 'w') do |csv| # rubocop:disable Metrics/BlockLength
    csv << ["Agent Conversation Details Report - #{agent.name} (#{agent.email})"]
    csv << ["Account ID: #{account_id}", "Agent ID: #{agent_id}"]
    csv << ["Reporting period: #{start_date} to #{end_date}"]
    csv << ['Note: Adjusted times exclude pending/snoozed periods']
    csv << []

    csv << [
      'Conversation ID',
      'Conversation Link',
      'Inbox Name',
      'Channel Type',
      'Status',
      'Created At',
      'Resolved At',
      'First Response Time',
      'Resolution Time (Original)',
      'Resolution Time (Adjusted)',
      'Avg Response Time (Original)',
      'Avg Response Time (Adjusted)',
      'Pending/Snoozed Time'
    ]

    conversations_data.each do |conv|
      csv << [
        conv[:conversation_id],
        conv[:conversation_link],
        conv[:inbox_name],
        conv[:channel_type],
        conv[:status],
        conv[:created_at]&.strftime('%Y-%m-%d %H:%M:%S'),
        conv[:resolved_at]&.strftime('%Y-%m-%d %H:%M:%S'),
        job.send(:format_time, conv[:first_response_time]),
        job.send(:format_time, conv[:resolution_time]),
        job.send(:format_time, conv[:resolution_time_adjusted]),
        job.send(:format_time, conv[:avg_response_time]),
        job.send(:format_time, conv[:avg_response_time_adjusted]),
        job.send(:format_time, conv[:pending_snoozed_time])
      ]
    end
  end

  puts "📄 CSV saved: #{file_name}"
  puts "File size: #{File.size(file_name)} bytes"

  # Upload to AWS using job's method
  puts "\n⬆️  Uploading to AWS..."
  csv_content = File.read(file_name)
  csv_url = job.send(:upload_to_storage, account_id, file_name, csv_content)
  puts '✅ Upload complete!'
  puts "\n🔗 AWS Link: #{csv_url}"

  # Summary Statistics
  puts "\n#{'=' * 80}"
  puts 'Summary Statistics'
  puts '=' * 80

  total_conversations = conversations_data.length
  resolved_conversations = conversations_data.count { |c| c[:status] == 'resolved' }

  total_frt = conversations_data.sum { |c| c[:first_response_time] }
  avg_frt = total_conversations.positive? ? total_frt / total_conversations : 0

  resolved_data = conversations_data.select { |c| c[:resolution_time].positive? }
  total_resolution = resolved_data.sum { |c| c[:resolution_time_adjusted] }
  avg_resolution = resolved_conversations.positive? ? total_resolution / resolved_conversations : 0

  total_response = conversations_data.sum { |c| c[:avg_response_time_adjusted] }
  avg_response = total_conversations.positive? ? total_response / total_conversations : 0

  puts "Total Conversations: #{total_conversations}"
  puts "Resolved Conversations: #{resolved_conversations}"
  puts "Avg First Response Time: #{job.send(:format_time, avg_frt)}"
  puts "Avg Resolution Time (Adjusted): #{job.send(:format_time, avg_resolution)}"
  puts "Avg Response Time (Adjusted): #{job.send(:format_time, avg_response)}"

  # Sample conversations
  puts "\n#{'=' * 80}"
  puts 'Sample Conversations (First 3)'
  puts '=' * 80

  conversations_data.first(3).each_with_index do |conv, idx|
    puts "\nConversation #{idx + 1}:"
    puts "  ID: #{conv[:conversation_id]}"
    puts "  Link: #{conv[:conversation_link]}"
    puts "  Inbox: #{conv[:inbox_name]}"
    puts "  Status: #{conv[:status]}"
    puts "  First Response Time: #{job.send(:format_time, conv[:first_response_time])}"
    puts "  Resolution Time (Adjusted): #{job.send(:format_time, conv[:resolution_time_adjusted])}"
    puts "  Avg Response Time (Adjusted): #{job.send(:format_time, conv[:avg_response_time_adjusted])}"
  end

  # Final output with AWS link
  puts "\n#{'=' * 80}"
  puts 'Report Complete!'
  puts '=' * 80
  puts "\n📊 Report Summary:"
  puts "  - Local File: #{file_name}"
  puts "  - File Size: #{File.size(file_name)} bytes"
  puts "  - Total Conversations: #{total_conversations}"
  puts "\n🔗 AWS Download Link:"
  puts "  #{csv_url}"
else
  puts '⚠️  No conversations found for this agent in the specified date range'
end

puts "\n#{'=' * 80}"
puts 'Script Complete!'
puts '=' * 80
