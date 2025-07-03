#!/usr/bin/env ruby

# Test script for Captain::Copilot::AgentsChatService
require_relative 'config/environment'

begin
  puts 'Starting AgentsChatService test...'

  # Find a copilot thread
  copilot_thread = CopilotThread.last
  if copilot_thread.nil?
    puts 'ERROR: No CopilotThread found'
    exit 1
  end
  puts "Found CopilotThread: #{copilot_thread.id}"

  # Create the service
  puts 'Creating AgentsChatService...'
  service = Captain::Copilot::AgentsChatService.new(
    copilot_thread: copilot_thread,
    message_content: 'Test message',
    conversation_id: 14_532,
    user_id: 1
  )
  puts 'Service created successfully'

  # Try to perform
  puts 'Calling service.perform...'
  service.perform
  puts 'Service completed successfully'

rescue StandardError => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts 'BACKTRACE:'
  e.backtrace.each { |line| puts "  #{line}" }
end