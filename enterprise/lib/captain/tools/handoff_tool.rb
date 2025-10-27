class Captain::Tools::HandoffTool < Captain::Tools::BasePublicTool
  description 'Hand off the conversation to a human agent when unable to assist further'
  param :reason, type: 'string', desc: 'The reason why handoff is needed (optional)', required: false

  def perform(tool_context, reason: nil)
    conversation = find_conversation(tool_context.state)
    return 'Conversation not found' unless conversation

    # Log the handoff with reason
    log_tool_usage('tool_handoff', {
                     conversation_id: conversation.id,
                     reason: reason || 'Agent requested handoff'
                   })

    # Use existing handoff mechanism from ResponseBuilderJob
    trigger_handoff(conversation, reason)

    "Conversation handed off to human support team#{" (Reason: #{reason})" if reason}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    'Failed to handoff conversation'
  end

  private

  def trigger_handoff(conversation, reason)
    debug_file = "tmp/conversation-#{conversation.id}.txt"

    File.open(debug_file, "a") do |f|
      f.puts "\n\n" + "-"*80
      f.puts "========== HANDOFF TOOL TRIGGER START =========="
      f.puts "Time: #{Time.current}"
      f.puts "Conversation ID: #{conversation.id}"
      f.puts "Conversation Status BEFORE: #{conversation.status}"
      f.puts "Conversation persisted?: #{conversation.persisted?}"
      f.puts "Current.executed_by BEFORE: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "Current.executed_by object_id: #{Current.executed_by&.object_id}"
      f.puts "Current.handoff_requested BEFORE: #{Current.handoff_requested.inspect}"
      f.puts "Reason: #{reason}"
      f.puts "Assistant: #{@assistant&.class&.name} - #{@assistant&.id}"
      f.puts "ActiveRecord transaction open?: #{conversation.class.connection.transaction_open?}"
      f.puts "Thread ID: #{Thread.current.object_id}"
      f.puts "Caller stack (first 10):"
      caller.first(10).each { |line| f.puts "  #{line}" }
    end

    File.open(debug_file, "a") do |f|
      f.puts "\nSetting Current.handoff_requested = true"
      f.puts "NOT calling bot_handoff! - letting ResponseBuilderJob handle it"
    end

    # Signal to ResponseBuilderJob that handoff is requested
    Current.handoff_requested = true

    File.open(debug_file, "a") do |f|
      f.puts "Current.handoff_requested set to: #{Current.handoff_requested.inspect}"
      f.puts "Current.executed_by AFTER: #{Current.executed_by&.class&.name} - #{Current.executed_by&.id}"
      f.puts "Conversation Status (unchanged): #{conversation.status}"
      f.puts "========== HANDOFF TOOL TRIGGER END ==========\n\n"
    end
  end

  # TODO: Future enhancement - Add team assignment capability
  # This tool could be enhanced to:
  # 1. Accept team_id parameter for routing to specific teams
  # 2. Set conversation priority based on handoff reason
  # 3. Add metadata for intelligent agent assignment
  # 4. Support escalation levels (L1 -> L2 -> L3)
  #
  # Example future signature:
  # param :team_id, type: 'string', desc: 'ID of team to assign conversation to', required: false
  # param :priority, type: 'string', desc: 'Priority level (low/medium/high/urgent)', required: false
  # param :escalation_level, type: 'string', desc: 'Support level (L1/L2/L3)', required: false
end
