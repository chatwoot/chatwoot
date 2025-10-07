# Test script for updated report jobs using V2::CustomReportBuilder
# Usage: rails runner test_updated_reports.rb

require 'csv'
require 'fileutils'

puts '=' * 80
puts 'Testing Updated Report Jobs with V2::CustomReportBuilder'
puts '=' * 80

account_id = 702
range = {
  since: 7.days.ago.beginning_of_day,
  until: 1.day.ago.end_of_day
}

start_date = range[:since].strftime('%Y-%m-%d')
end_date = range[:until].strftime('%Y-%m-%d')
timestamp = Time.current.strftime('%Y%m%d_%H%M%S')

puts "\nTest Configuration:"
puts "  Account ID: #{account_id}"
puts "  Date Range: #{start_date} to #{end_date}"
puts "  Output Directory: #{Dir.pwd}"

# Test 1: Inbox Channel Report
puts "\n" + ('=' * 80)
puts 'TEST 1: WeeklyInboxChannelReportJob'
puts '=' * 80

begin
  job = WeeklyInboxChannelReportJob.new
  job.send(:set_statement_timeout)

  puts '  Generating report...'
  start_time = Time.current
  report = job.send(:generate_report, account_id, range)
  duration = ((Time.current - start_time) * 1000).round(2)

  puts "  ✅ Report generated successfully in #{duration}ms"
  puts "  Total inboxes in report: #{report.length}"

  if report.any?
    # Generate and save CSV
    csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
    file_name = "test_inbox_channel_report_#{account_id}_#{timestamp}.csv"
    File.write(file_name, csv_content)
    puts "  📄 CSV saved: #{file_name}"

    sample_inbox = report.first
    puts "\n  Sample Inbox Data:"
    puts "    Name: #{sample_inbox[:inbox_name]}"
    puts "    Channel: #{sample_inbox[:channel_type]}"
    puts "    Total Tickets Assigned: #{sample_inbox[:metrics][:total_tickets_assigned]}"
    puts "    New Chats Created: #{sample_inbox[:metrics][:new_chats_created]}"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

# Test 2: Agent Level Report
puts "\n" + ('=' * 80)
puts 'TEST 2: WeeklyAgentLevelReportJob'
puts '=' * 80

begin
  job = WeeklyAgentLevelReportJob.new
  job.send(:set_statement_timeout)

  puts '  Generating report...'
  start_time = Time.current
  report = job.send(:generate_report, account_id, range)
  duration = ((Time.current - start_time) * 1000).round(2)

  puts "  ✅ Report generated successfully in #{duration}ms"
  puts "  Total agent-inbox combinations: #{report.length}"

  if report.any?
    # Generate and save CSV
    csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
    file_name = "test_agent_level_report_#{account_id}_#{timestamp}.csv"
    File.write(file_name, csv_content)
    puts "  📄 CSV saved: #{file_name}"

    sample_agent = report.first
    puts "\n  Sample Agent Data:"
    puts "    Agent: #{sample_agent[:agent_name]}"
    puts "    Inbox: #{sample_agent[:inbox_name]}"
    puts "    Total Chats Handled: #{sample_agent[:metrics][:total_chats_handled]}"
    puts "    Total Chats Resolved: #{sample_agent[:metrics][:total_chats_resolved]}"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

# Test 3: Bot Report
puts "\n" + ('=' * 80)
puts 'TEST 3: WeeklyBotReportJob'
puts '=' * 80

begin
  job = WeeklyBotReportJob.new
  job.send(:set_statement_timeout)

  puts '  Generating report...'
  start_time = Time.current
  report = job.send(:generate_report, account_id, range)
  duration = ((Time.current - start_time) * 1000).round(2)

  puts "  ✅ Report generated successfully in #{duration}ms"
  puts "  Total bot-inbox combinations: #{report.length}"

  if report.any?
    # Generate and save CSV
    csv_content = job.send(:generate_csv, report, start_date, end_date, account_id)
    file_name = "test_bot_report_#{account_id}_#{timestamp}.csv"
    File.write(file_name, csv_content)
    puts "  📄 CSV saved: #{file_name}"

    sample_bot = report.first
    puts "\n  Sample Bot Data:"
    puts "    Bot: #{sample_bot[:bot_name]}"
    puts "    Inbox: #{sample_bot[:inbox_name]}"
    puts "    Channel: #{sample_bot[:channel_type]}"
    puts "    Total Chats Handled: #{sample_bot[:metrics][:total_chats_handled]}"
    puts "    Total Assigned to Agent: #{sample_bot[:metrics][:total_assigned_to_agent]}"
  end
rescue StandardError => e
  puts "  ❌ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

puts "\n" + ('=' * 80)
puts 'Test Complete!'
puts '=' * 80

puts "\n📁 Generated Files:"
Dir.glob("test_*_report_#{account_id}_#{timestamp}.csv").each do |file|
  puts "  ✓ #{file} (#{File.size(file)} bytes)"
end
