# frozen_string_literal: true

# Test: Balanced Selector Strategy (Enterprise)
# Run with: bundle exec rails runner script/assignment_v2/test_balanced_selector.rb
#
# Tests:
# - Balanced selector assigns to agent with least open conversations
# - When agents have equal workload, any can be chosen
# - Workload is recalculated for each assignment (not cached)
# - Balanced selector produces different distribution than round-robin
#
# Key Implementation Details:
# - AssignmentPolicy has assignment_order enum: { round_robin: 0, balanced: 1 } (Enterprise)
# - Enterprise::AutoAssignment::AssignmentService uses balanced_selector when policy.balanced?
# - BalancedSelector.select_agent(agents) returns agent with min open conversation count
# - Counts are fetched fresh for each assignment: inbox.conversations.open.where(assignee_id: user_ids).count
# - This enables real-time workload balancing within a single assignment batch

require_relative 'test_helpers'

class TestBalancedSelector
  include AssignmentV2TestHelpers

  def run
    skip_if_not_enterprise

    section('TEST: Balanced Selector Strategy (Enterprise)')

    account = get_test_account
    inbox = nil

    begin
      # Setup test inbox with balanced policy
      inbox = create_test_inbox(account, name: 'Balanced Selector Test Inbox')

      # Create policy with balanced assignment order
      policy = create_test_policy(
        account,
        name: 'Balanced Test Policy',
        assignment_order: 'balanced'  # Enterprise: balanced selector
      )
      link_policy_to_inbox(inbox, policy)

      info('Created policy with assignment_order: balanced')

      # Test 1: Initial balanced distribution
      section('Test 1: Balanced Distribution from Zero')

      # Create 3 agents
      agent_1 = create_test_agent(account, inbox, name: 'Agent 1', online: true)
      agent_2 = create_test_agent(account, inbox, name: 'Agent 2', online: true)
      agent_3 = create_test_agent(account, inbox, name: 'Agent 3', online: true)

      # Create 9 conversations (3 per agent if perfectly balanced)
      create_bulk_conversations(inbox, count: 9)

      # Run assignment
      assigned_count = run_assignment(inbox)

      # Verify balanced distribution
      log('Verifying initial balanced distribution...', color: :blue)

      # All 9 should be assigned
      all_assigned = assert_equal(
        assigned_count,
        9,
        'All 9 conversations assigned'
      )

      # Check distribution - should be 3 each (or as close as possible)
      agent_1_count = inbox.conversations.where(assignee: agent_1).count
      agent_2_count = inbox.conversations.where(assignee: agent_2).count
      agent_3_count = inbox.conversations.where(assignee: agent_3).count

      # All agents should have 3 conversations (perfect balance)
      balanced_ok = assert(
        agent_1_count == 3 && agent_2_count == 3 && agent_3_count == 3,
        "Balanced distribution: #{agent_1.name}=3, #{agent_2.name}=3, #{agent_3.name}=3",
        "Unbalanced: #{agent_1.name}=#{agent_1_count}, #{agent_2.name}=#{agent_2_count}, #{agent_3.name}=#{agent_3_count}"
      )

      test1_ok = all_assigned && balanced_ok

      # Test 2: Rebalancing when agents have unequal workloads
      section('Test 2: Rebalancing Unequal Workloads')

      # Manually assign 5 more conversations to agent_1 (simulating prior workload)
      manual_conversations = create_bulk_conversations(inbox, count: 5)
      manual_conversations.each { |conv| conv.update!(assignee: agent_1) }
      info("Manually assigned 5 conversations to #{agent_1.name}")

      # Current state: agent_1 = 8, agent_2 = 3, agent_3 = 3

      # Create 6 more conversations to assign
      create_bulk_conversations(inbox, count: 6)

      # Run assignment - balanced selector should favor agent_2 and agent_3
      assigned_count_2 = run_assignment(inbox)

      # Verify rebalancing behavior
      log('Verifying rebalancing...', color: :blue)

      # All 6 should be assigned
      all_assigned_2 = assert_equal(
        assigned_count_2,
        6,
        'All 6 new conversations assigned'
      )

      # Check new distribution
      agent_1_new = inbox.conversations.where(assignee: agent_1, status: 'open').count
      agent_2_new = inbox.conversations.where(assignee: agent_2, status: 'open').count
      agent_3_new = inbox.conversations.where(assignee: agent_3, status: 'open').count

      info("After rebalancing: #{agent_1.name}=#{agent_1_new}, #{agent_2.name}=#{agent_2_new}, #{agent_3.name}=#{agent_3_new}")

      # agent_1 should still have 8 (no new assignments because already overloaded)
      # agent_2 and agent_3 should have gotten the 6 new ones (3 each)
      rebalanced_ok = assert(
        agent_1_new == 8 && agent_2_new == 6 && agent_3_new == 6,
        'Balanced selector avoided overloaded agent',
        "Unexpected distribution: #{agent_1.name}=#{agent_1_new}, #{agent_2.name}=#{agent_2_new}, #{agent_3.name}=#{agent_3_new}"
      )

      test2_ok = all_assigned_2 && rebalanced_ok

      # Test 3: Compare with round-robin behavior
      section('Test 3: Balanced vs Round-Robin Comparison')

      # Create a second inbox with round-robin policy for comparison
      inbox_rr = create_test_inbox(account, name: 'Round-Robin Comparison Inbox')
      policy_rr = create_test_policy(
        account,
        name: 'Round-Robin Policy',
        assignment_order: 'round_robin'
      )
      link_policy_to_inbox(inbox_rr, policy_rr)

      # Add same 3 agents to this inbox
      inbox_rr.inbox_members.create!(user: agent_1)
      inbox_rr.inbox_members.create!(user: agent_2)
      inbox_rr.inbox_members.create!(user: agent_3)

      # Give agent_1 a head start (5 conversations in round-robin inbox)
      rr_manual = create_bulk_conversations(inbox_rr, count: 5)
      rr_manual.each { |conv| conv.update!(assignee: agent_1) }
      info("Round-robin inbox: Manually assigned 5 to #{agent_1.name}")

      # Create 6 more conversations in round-robin inbox
      create_bulk_conversations(inbox_rr, count: 6)

      # Run assignment with round-robin
      run_assignment(inbox_rr)

      # Check round-robin distribution
      agent_1_rr = inbox_rr.conversations.where(assignee: agent_1, status: 'open').count
      agent_2_rr = inbox_rr.conversations.where(assignee: agent_2, status: 'open').count
      agent_3_rr = inbox_rr.conversations.where(assignee: agent_3, status: 'open').count

      info("Round-robin distribution: #{agent_1.name}=#{agent_1_rr}, #{agent_2.name}=#{agent_2_rr}, #{agent_3.name}=#{agent_3_rr}")

      # Round-robin will assign 2 to each agent (6 ÷ 3 = 2 each), resulting in:
      # agent_1 = 7, agent_2 = 2, agent_3 = 2 (unbalanced!)
      rr_unbalanced = assert(
        agent_1_rr > agent_2_rr && agent_1_rr > agent_3_rr,
        'Round-robin creates unbalanced distribution when starting unequal',
        'Round-robin distribution was balanced (unexpected)'
      )

      # Compare: balanced inbox should be more even
      balanced_diff = (agent_1_new - agent_2_new).abs + (agent_2_new - agent_3_new).abs + (agent_1_new - agent_3_new).abs
      rr_diff = (agent_1_rr - agent_2_rr).abs + (agent_2_rr - agent_3_rr).abs + (agent_1_rr - agent_3_rr).abs

      better_balance = assert(
        balanced_diff < rr_diff,
        "Balanced selector (diff=#{balanced_diff}) is more even than round-robin (diff=#{rr_diff})",
        "Balanced selector (diff=#{balanced_diff}) not better than round-robin (diff=#{rr_diff})"
      )

      test3_ok = rr_unbalanced && better_balance

      # Show final comparison
      log('Final Comparison:', color: :blue)
      puts "  Balanced Inbox: #{agent_1.name}=#{agent_1_new}, #{agent_2.name}=#{agent_2_new}, #{agent_3.name}=#{agent_3_new}"
      puts "  Round-Robin Inbox: #{agent_1.name}=#{agent_1_rr}, #{agent_2.name}=#{agent_2_rr}, #{agent_3.name}=#{agent_3_rr}"

      # Cleanup round-robin inbox
      cleanup_test_data(account, inbox: inbox_rr)

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
exit(TestBalancedSelector.new.run ? 0 : 1)
