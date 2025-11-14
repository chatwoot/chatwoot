# frozen_string_literal: true

# Test: Agent Capacity Limits (Enterprise)
# Run with: bundle exec rails runner script/assignment_v2/test_capacity_limits.rb
#
# Tests:
# - Agents respect inbox-specific capacity limits
# - When agent reaches limit, new conversations go to other agents
# - Agents without capacity policy have unlimited capacity
# - Capacity is per-inbox (agent can have different limits for different inboxes)
#
# Key Implementation Details:
# - AgentCapacityPolicy is linked to AccountUser (not User directly)
# - InboxCapacityLimit defines conversation_limit per inbox for a policy
# - CapacityService.agent_has_capacity? checks: current_open_conversations < limit
# - Enterprise::AutoAssignment::AssignmentService#filter_agents_by_capacity filters agents
# - Capacity filtering only happens when:
#   1. assignment_v2 feature is enabled
#   2. Account has at least one AccountUser with agent_capacity_policy

require_relative 'test_helpers'

class TestCapacityLimits
  include AssignmentV2TestHelpers

  def run
    skip_if_not_enterprise

    section('TEST: Agent Capacity Limits (Enterprise)')

    account = get_test_account
    inbox = nil

    begin
      # Setup test inbox and policy
      inbox = create_test_inbox(account, name: 'Capacity Test Inbox')
      policy = create_test_policy(account, name: 'Capacity Test Policy')
      link_policy_to_inbox(inbox, policy)

      # Test 1: Agents with capacity limits
      section('Test 1: Agents Respect Capacity Limits')

      # Create 2 agents
      agent_limited = create_test_agent(account, inbox, name: 'Agent Limited', online: true)
      agent_unlimited = create_test_agent(account, inbox, name: 'Agent Unlimited', online: true)

      # Create capacity policy with limit of 3 conversations per agent for this inbox
      capacity_policy = account.agent_capacity_policies.create!(
        name: "Capacity Policy #{SecureRandom.hex(4)}",
        exclusion_rules: {}
      )

      # Link capacity policy to the inbox with a limit of 3
      capacity_policy.inbox_capacity_limits.create!(
        inbox: inbox,
        conversation_limit: 3
      )

      # Link capacity policy to agent_limited's account_user
      account_user_limited = account.account_users.find_by(user: agent_limited)
      account_user_limited.update!(agent_capacity_policy: capacity_policy)

      info("#{agent_limited.name} has capacity limit of 3 for inbox #{inbox.id}")
      info("#{agent_unlimited.name} has no capacity limit")

      # Create 8 conversations
      # Expected distribution:
      # - agent_limited: 3 (hits capacity limit)
      # - agent_unlimited: 5 (takes remaining conversations)
      create_bulk_conversations(inbox, count: 8)

      # Run assignment
      assigned_count = run_assignment(inbox)

      # Verify capacity limits respected
      log('Verifying capacity limits...', color: :blue)

      # All 8 should be assigned
      all_assigned = assert_equal(
        assigned_count,
        8,
        'All 8 conversations assigned'
      )

      # Agent_limited should have exactly 3 (at capacity limit)
      limited_count = inbox.conversations.where(assignee: agent_limited).count
      limited_at_capacity = assert_equal(
        limited_count,
        3,
        "#{agent_limited.name} has 3 conversations (at capacity)"
      )

      # Agent_unlimited should have 5 (took the rest)
      unlimited_count = inbox.conversations.where(assignee: agent_unlimited).count
      unlimited_got_rest = assert_equal(
        unlimited_count,
        5,
        "#{agent_unlimited.name} has 5 conversations (no limit)"
      )

      test1_ok = all_assigned && limited_at_capacity && unlimited_got_rest

      # Test 2: More conversations arrive - only unlimited agent gets them
      section('Test 2: Limited Agent at Capacity')

      # Create 3 more conversations
      create_bulk_conversations(inbox, count: 3)

      # Run assignment
      assigned_count_2 = run_assignment(inbox)

      # Verify only unlimited agent gets assignments
      log('Verifying only unlimited agent gets new assignments...', color: :blue)

      # All 3 should be assigned
      all_assigned_2 = assert_equal(
        assigned_count_2,
        3,
        'All 3 new conversations assigned'
      )

      # Agent_limited still has 3 (at capacity, gets no new ones)
      limited_still_count = inbox.conversations.where(assignee: agent_limited).count
      limited_unchanged = assert_equal(
        limited_still_count,
        3,
        "#{agent_limited.name} still has 3 (at capacity)"
      )

      # Agent_unlimited now has 8 (5 + 3)
      unlimited_new_count = inbox.conversations.where(assignee: agent_unlimited).count
      unlimited_got_all_new = assert_equal(
        unlimited_new_count,
        8,
        "#{agent_unlimited.name} has 8 conversations (got all new ones)"
      )

      test2_ok = all_assigned_2 && limited_unchanged && unlimited_got_all_new

      # Test 3: Resolve some conversations - capacity frees up
      section('Test 3: Capacity Frees Up When Conversations Resolve')

      # Resolve 2 of agent_limited's conversations
      agent_limited_conversations = inbox.conversations.where(assignee: agent_limited).limit(2)
      agent_limited_conversations.each { |conv| conv.update!(status: 'resolved') }
      info("Resolved 2 of #{agent_limited.name}'s conversations")

      # Create 4 more conversations
      create_bulk_conversations(inbox, count: 4)

      # Run assignment
      assigned_count_3 = run_assignment(inbox)

      # Verify agent_limited can get assignments again (up to capacity)
      log('Verifying capacity freed up...', color: :blue)

      # All 4 should be assigned
      all_assigned_3 = assert_equal(
        assigned_count_3,
        4,
        'All 4 final conversations assigned'
      )

      # Agent_limited should have 3 open conversations again (was 1, got 2 more)
      limited_open_count = inbox.conversations.where(assignee: agent_limited, status: 'open').count
      limited_filled_capacity = assert_equal(
        limited_open_count,
        3,
        "#{agent_limited.name} has 3 open conversations (capacity filled again)"
      )

      # Agent_unlimited should have 10 open conversations (8 + 2)
      unlimited_final_count = inbox.conversations.where(assignee: agent_unlimited, status: 'open').count
      unlimited_got_remainder = assert_equal(
        unlimited_final_count,
        10,
        "#{agent_unlimited.name} has 10 open conversations (got remainder)"
      )

      test3_ok = all_assigned_3 && limited_filled_capacity && unlimited_got_remainder

      # Show final distribution (open only)
      log('Final Distribution (open conversations only):', color: :blue)
      puts "  #{agent_limited.name}: #{limited_open_count} conversations (limit: 3)"
      puts "  #{agent_unlimited.name}: #{unlimited_final_count} conversations (no limit)"

      # Final result
      if test1_ok && test2_ok && test3_ok
        section('✓ ALL TESTS PASSED')
        true
      else
        section('✗ SOME TESTS FAILED')
        false
      end
    rescue StandardError => e
      error("Test failed with error: #{e.message}")
      puts e.backtrace.first(5).join("\n")
      false
    ensure
      cleanup_test_data(account, inbox: inbox) if inbox
    end
  end
end

# Run test and exit with appropriate code
exit(TestCapacityLimits.new.run ? 0 : 1)
