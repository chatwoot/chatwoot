# Usage: bundle exec rails runner lib/scripts/sankey_data_generator.rb [account_id] [days]
# Example: bundle exec rails runner lib/scripts/sankey_data_generator.rb 2 30
#
# Generates Sankey diagram data from reporting_events for conversation flow visualization.
# The flow shows: Conversations → Bot/Direct → Resolution paths

class SankeyDataGenerator
  def initialize(account_id:, days: 90)
    @account_id = account_id
    @days = days
  end

  def generate
    {
      nodes: build_nodes,
      links: build_links
    }
  end

  def to_json(*_args)
    JSON.pretty_generate(generate)
  end

  private

  def base_scope
    ReportingEvent.where(account_id: @account_id).where('conversation_created_at >= ?', @days.days.ago)
  end

  def conversation_created
    @conversation_created ||= base_scope.where(name: 'conversation_created').distinct.count(:conversation_id)
  end

  def bot_handoff
    @bot_handoff ||= base_scope.where(name: 'conversation_bot_handoff').distinct.count(:conversation_id)
  end

  def bot_resolved
    @bot_resolved ||= begin
      # Exclude conversations that were later handed off (they go through handoff flow instead)
      bot_resolved_ids = base_scope.where(name: 'conversation_bot_resolved').distinct.pluck(:conversation_id)
      handoff_ids = base_scope.where(name: 'conversation_bot_handoff').distinct.pluck(:conversation_id)
      (bot_resolved_ids - handoff_ids).count
    end
  end

  def agent_resolved
    @agent_resolved ||= base_scope.where(name: 'conversation_resolved').distinct.count(:conversation_id)
  end

  def reopened_conversation_ids
    @reopened_conversation_ids ||= base_scope
                                   .where(name: 'conversation_opened', from_state: 'resolved')
                                   .distinct
                                   .pluck(:conversation_id)
  end

  def reopened
    @reopened ||= reopened_conversation_ids.count
  end

  # Reopened from bot_resolved (exclusive - not handed off after)
  def reopened_from_bot
    @reopened_from_bot ||= begin
      bot_resolved_ids = base_scope.where(name: 'conversation_bot_resolved').pluck(:conversation_id)
      handoff_ids = base_scope.where(name: 'conversation_bot_handoff').pluck(:conversation_id)
      # Only count if bot_resolved but NOT handed off (stayed in bot flow)
      bot_only_ids = bot_resolved_ids - handoff_ids
      (reopened_conversation_ids & bot_only_ids).count
    end
  end

  # Reopened from handoff_resolved (went through handoff path)
  def reopened_from_handoff
    @reopened_from_handoff ||= begin
      handoff_ids = base_scope.where(name: 'conversation_bot_handoff').pluck(:conversation_id)
      resolved_after_handoff_ids = base_scope
                                   .where(name: 'conversation_resolved', conversation_id: handoff_ids)
                                   .pluck(:conversation_id)
      (reopened_conversation_ids & resolved_after_handoff_ids).count
    end
  end

  # Reopened from direct agent resolution (no bot involvement)
  def reopened_from_direct
    @reopened_from_direct ||= [reopened - reopened_from_bot - reopened_from_handoff, 0].max
  end

  # Conversations assigned to bot (created in bot-enabled inboxes)
  def bot_assigned
    @bot_assigned ||= begin
      return 0 if bot_inbox_ids.empty?

      base_scope.where(name: 'conversation_created', inbox_id: bot_inbox_ids).distinct.count(:conversation_id)
    end
  end

  # Conversations that went directly to agent (no bot involvement)
  def direct_to_agent
    @direct_to_agent ||= [conversation_created - bot_assigned, 0].max
  end

  # Count conversations that have both bot_handoff AND conversation_resolved events
  def resolved_after_handoff
    @resolved_after_handoff ||= begin
      handoff_conversation_ids = base_scope
                                 .where(name: 'conversation_bot_handoff')
                                 .distinct
                                 .pluck(:conversation_id)

      return 0 if handoff_conversation_ids.empty?

      base_scope
        .where(name: 'conversation_resolved')
        .where(conversation_id: handoff_conversation_ids)
        .distinct
        .count(:conversation_id)
    end
  end

  # Agent resolutions from direct conversations (no bot involvement)
  def resolved_direct_by_agent
    @resolved_direct_by_agent ||= begin
      # Get conversation IDs that went direct to agent (not in bot inboxes)
      direct_conversation_ids = base_scope
                                .where(name: 'conversation_created')
                                .where.not(inbox_id: bot_inbox_ids)
                                .distinct
                                .pluck(:conversation_id)

      return 0 if direct_conversation_ids.empty?

      base_scope
        .where(name: 'conversation_resolved')
        .where(conversation_id: direct_conversation_ids)
        .distinct
        .count(:conversation_id)
    end
  end

  def bot_inbox_ids
    @bot_inbox_ids ||= Inbox.where(account_id: @account_id).select(&:active_bot?).map(&:id)
  end

  # Unresolved at bot level (assigned to bot but not resolved or handed off yet)
  def unresolved_at_bot
    @unresolved_at_bot ||= [bot_assigned - bot_resolved - bot_handoff, 0].max
  end

  # Unresolved after handoff (handed off but not yet resolved)
  def unresolved_after_handoff
    @unresolved_after_handoff ||= [bot_handoff - resolved_after_handoff, 0].max
  end

  # Unresolved direct (went to agent but not yet resolved)
  def unresolved_direct
    @unresolved_direct ||= [direct_to_agent - resolved_direct_by_agent, 0].max
  end

  def build_nodes
    [
      { id: 'conversations', label: 'Conversations', value: conversation_created, subgroups: %w[bot_flow agent_direct] },

      { id: 'bot_flow', label: 'Assigned to Bot', value: bot_assigned,
        subgroups: %w[bot_resolved bot_handoff bot_unresolved] },

      { id: 'agent_direct', label: 'Direct to Agent', value: direct_to_agent,
        subgroups: %w[agent_direct_resolved agent_direct_unresolved] },

      { id: 'bot_resolved', label: 'Resolved by Bot', value: bot_resolved,
        subgroups: %w[bot_resolved_final bot_resolved_reopened] },

      { id: 'bot_resolved_final', label: 'Stayed Resolved', value: bot_resolved - reopened_from_bot, subgroups: [] },
      { id: 'bot_resolved_reopened', label: 'Reopened', value: reopened_from_bot, subgroups: [] },

      { id: 'bot_handoff', label: 'Handed off to Agent', value: bot_handoff,
        subgroups: %w[handoff_resolved handoff_unresolved] },

      { id: 'bot_unresolved', label: 'Unresolved (Bot)', value: unresolved_at_bot, subgroups: [] },

      { id: 'handoff_resolved', label: 'Resolved by Agent', value: resolved_after_handoff,
        subgroups: %w[handoff_resolved_final handoff_resolved_reopened] },

      { id: 'handoff_resolved_final', label: 'Stayed Resolved', value: resolved_after_handoff - reopened_from_handoff, subgroups: [] },
      { id: 'handoff_resolved_reopened', label: 'Reopened', value: reopened_from_handoff, subgroups: [] },

      { id: 'handoff_unresolved', label: 'Unresolved', value: unresolved_after_handoff, subgroups: [] },

      { id: 'agent_direct_resolved', label: 'Resolved by Agent', value: resolved_direct_by_agent,
        subgroups: %w[agent_direct_resolved_final agent_direct_resolved_reopened] },

      { id: 'agent_direct_resolved_final', label: 'Stayed Resolved', value: resolved_direct_by_agent - reopened_from_direct, subgroups: [] },
      { id: 'agent_direct_resolved_reopened', label: 'Reopened', value: reopened_from_direct, subgroups: [] },

      { id: 'agent_direct_unresolved', label: 'Unresolved', value: unresolved_direct, subgroups: [] }
    ]
  end

  def build_links
    [
      { source: 'root', target: 'conversations', value: conversation_created },

      { source: 'conversations', target: 'bot_flow', value: bot_assigned },
      { source: 'conversations', target: 'agent_direct', value: direct_to_agent },

      { source: 'bot_flow', target: 'bot_resolved', value: bot_resolved },
      { source: 'bot_flow', target: 'bot_handoff', value: bot_handoff },
      { source: 'bot_flow', target: 'bot_unresolved', value: unresolved_at_bot },

      { source: 'bot_resolved', target: 'bot_resolved_final', value: bot_resolved - reopened_from_bot },
      { source: 'bot_resolved', target: 'bot_resolved_reopened', value: reopened_from_bot },

      { source: 'bot_handoff', target: 'handoff_resolved', value: resolved_after_handoff },
      { source: 'bot_handoff', target: 'handoff_unresolved', value: unresolved_after_handoff },

      { source: 'handoff_resolved', target: 'handoff_resolved_final', value: resolved_after_handoff - reopened_from_handoff },
      { source: 'handoff_resolved', target: 'handoff_resolved_reopened', value: reopened_from_handoff },

      { source: 'agent_direct', target: 'agent_direct_resolved', value: resolved_direct_by_agent },
      { source: 'agent_direct', target: 'agent_direct_unresolved', value: unresolved_direct },

      { source: 'agent_direct_resolved', target: 'agent_direct_resolved_final', value: resolved_direct_by_agent - reopened_from_direct },
      { source: 'agent_direct_resolved', target: 'agent_direct_resolved_reopened', value: reopened_from_direct }
    ]
  end
end

if __FILE__ == $PROGRAM_NAME
  account_id = ARGV[0]&.to_i || 2
  days = ARGV[1]&.to_i || 90

  generator = SankeyDataGenerator.new(account_id: account_id, days: days)
  puts generator.to_json
end
