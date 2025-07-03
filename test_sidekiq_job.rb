#!/usr/bin/env ruby

# Test script for running the Sidekiq job directly
require_relative 'config/environment'

begin
  puts 'Starting Sidekiq job test...'

  # Find a copilot thread
  copilot_thread = CopilotThread.last
  if copilot_thread.nil?
    puts 'ERROR: No CopilotThread found'
    exit 1
  end
  puts "Found CopilotThread: #{copilot_thread.id}"

  # Run the job directly (not through Sidekiq)
  puts 'Running AgentsResponseJob directly...'
  job = Captain::Copilot::AgentsResponseJob.new
  job.perform(
    copilot_thread_id: copilot_thread.id,
    message_content: 'Test message',
    conversation_id: 14_532,
    user_id: 1
  )
  puts 'Job completed successfully'

rescue StandardError => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts 'BACKTRACE:'
  e.backtrace.each { |line| puts "  #{line}" }
end