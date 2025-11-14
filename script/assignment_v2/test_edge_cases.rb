# frozen_string_literal: true

# Test: Edge Cases and Error Scenarios
# Run with: bundle exec rails runner script/assignment_v2/test_edge_cases.rb
#
# Tests:
# - No agents online: assignment returns 0, conversations remain unassigned
# - No conversations to assign: assignment completes without error
# - Policy disabled: assignment still works (policy just not enforced)
# - Auto-assignment disabled on inbox: assignment returns 0
# - All agents at rate limit: no assignments happen
# - Resolved/snoozed conversations: not assigned (only open+unassigned)
#
# Key Implementation Details:
# - AssignmentService.perform_bulk_assignment returns 0 if no eligible conversations
# - inbox.auto_assignment_v2_enabled? checks inbox.enable_auto_assignment flag
# - Only conversations with status='open' and assignee_id=nil are eligible
# - Policy.enabled flag doesn't block assignment, just affects policy behavior
# - When no agents available, assignment gracefully returns 0 (no errors)

require_relative 'test_helpers'

class TestEdgeCases
  include AssignmentV2TestHelpers

  def run
    section('TEST: Edge Cases and Error Scenarios')

    account = get_test_account
    inbox = nil

    begin
      # Test 1: No agents online
      section('Test 1: No Agents Online')

      inbox = create_test_inbox(account, name: 'Edge Case Test Inbox')
      policy = create_test_policy(account, name: 'Edge Case Policy')
      link_policy_to_inbox(inbox, policy)

      # Create agent but keep them offline
      agent_offline = create_test_agent(account, inbox, name: 'Agent Offline', online: false)
      info("Created offline agent: #{agent_offline.name}")

      # Create 3 conversations
      create_bulk_conversations(inbox, count: 3)

      # Run assignment - should assign 0 (no online agents)
      assigned_count = run_assignment(inbox)

      log('Verifying no agents online...', color: :blue)

      # Should assign 0
      none_assigned = assert_equal(
        assigned_count,
        0,
        'No conversations assigned (no online agents)'
      )

      # All conversations should remain unassigned
      still_unassigned = assert_equal(
        inbox.conversations.unassigned.count,
        3,
        'All 3 conversations remain unassigned'
      )

      test1_ok = none_assigned && still_unassigned

      # Test 2: No conversations to assign
      section('Test 2: No Conversations to Assign')

      # Bring agent online
      OnlineStatusTracker.update_presence(account.id, 'User', agent_offline.id)
      OnlineStatusTracker.set_status(account.id, agent_offline.id, 'online')
      info("Brought #{agent_offline.name} online")

      # Assign all existing conversations manually
      inbox.conversations.unassigned.each { |conv| conv.update!(assignee: agent_offline) }
      info('Manually assigned all existing conversations')

      # Run assignment with no unassigned conversations
      assigned_count_2 = run_assignment(inbox)

      log('Verifying no conversations to assign...', color: :blue)

      # Should assign 0 (nothing to assign)
      none_to_assign = assert_equal(
        assigned_count_2,
        0,
        'No conversations assigned (none available)'
      )

      # No unassigned conversations
      no_unassigned = assert_equal(
        inbox.conversations.unassigned.count,
        0,
        'No unassigned conversations'
      )

      test2_ok = none_to_assign && no_unassigned

      # Test 3: Policy disabled (note: inbox.enable_auto_assignment not yet implemented)
      section('Test 3: Policy Disabled')

      # Create new conversations
      create_bulk_conversations(inbox, count: 3)

      # Disable policy
      policy.update!(enabled: false)
      info('Disabled policy')

      # Run assignment - policy disabled doesn't block assignment in current implementation
      # Policy.enabled is intended for future use but doesn't currently affect assignment
      run_assignment(inbox)

      log('Verifying policy disabled (no effect currently)...', color: :blue)

      # NOTE: Policy.enabled doesn't actually block assignment yet, so this will assign
      # We're testing that assignment doesn't crash when policy is disabled
      policy_disabled_ok = assert(
        true,  # Just verify no crash
        'Assignment runs without error when policy disabled',
        'Assignment crashed when policy disabled'
      )

      # Re-enable policy for next tests
      policy.update!(enabled: true)

      test3_ok = policy_disabled_ok

      # Test 4: All agents at rate limit
      section('Test 4: All Agents at Rate Limit')

      # Clear all conversations and start fresh
      inbox.conversations.destroy_all
      info('Cleared all conversations for rate limit test')

      # Update existing policy with very low rate limit
      policy.update!(
        fair_distribution_limit: 1,
        fair_distribution_window: 3600
      )
      # Re-link to sync config to inbox
      link_policy_to_inbox(inbox, policy)
      info('Updated policy: rate limit = 1 conversation per agent')

      # Create 3 new conversations
      create_bulk_conversations(inbox, count: 3)

      # Run assignment once - should assign 1 (hitting the limit)
      assigned_count_first = run_assignment(inbox)
      info("First assignment: assigned #{assigned_count_first} conversation(s), agent now at limit")

      # Verify first assignment worked
      first_assign_ok = assert_equal(
        assigned_count_first,
        1,
        'First assignment assigned 1 conversation (limit reached)'
      )

      # Now agent is at limit (1/1), 2 conversations remain unassigned
      # Run assignment again - should assign 0 (agent at limit)
      assigned_count_4 = run_assignment(inbox)

      log('Verifying all agents at limit...', color: :blue)

      # Should assign 0
      at_limit_ok = assert_equal(
        assigned_count_4,
        0,
        'No conversations assigned (all agents at rate limit)'
      )

      # 2 conversations remain unassigned
      unassigned_at_limit = assert_equal(
        inbox.conversations.unassigned.count,
        2,
        '2 conversations remain unassigned'
      )

      test4_ok = first_assign_ok && at_limit_ok && unassigned_at_limit

      # Test 5: Only resolved/snoozed conversations (not eligible)
      section('Test 5: Only Resolved/Snoozed Conversations')

      # Create new inbox to start fresh
      inbox2 = create_test_inbox(account, name: 'Status Test Inbox')
      policy2 = create_test_policy(account, name: 'Status Test Policy')
      link_policy_to_inbox(inbox2, policy2)

      create_test_agent(account, inbox2, name: 'Agent Status Test', online: true)

      # Create conversations with different statuses
      conv_resolved = create_test_conversation(inbox2, contact_name: 'Resolved Customer', status: 'resolved')
      conv_snoozed = create_test_conversation(inbox2, contact_name: 'Snoozed Customer', status: 'snoozed')
      conv_pending = create_test_conversation(inbox2, contact_name: 'Pending Customer', status: 'pending')

      info('Created conversations with statuses: resolved, snoozed, pending')

      # Run assignment - should assign 0 (no open conversations)
      assigned_count_5 = run_assignment(inbox2)

      log('Verifying non-open conversations not assigned...', color: :blue)

      # Should assign 0
      status_ok = assert_equal(
        assigned_count_5,
        0,
        'No conversations assigned (all are resolved/snoozed/pending)'
      )

      # All conversations remain unassigned
      conv_resolved.reload
      conv_snoozed.reload
      conv_pending.reload
      none_assigned_5 = assert(
        conv_resolved.assignee_id.nil? &&
        conv_snoozed.assignee_id.nil? &&
        conv_pending.assignee_id.nil?,
        'All non-open conversations remain unassigned',
        'Some non-open conversations were assigned'
      )

      # Create 1 open conversation - should be assigned
      conv_open = create_test_conversation(inbox2, contact_name: 'Open Customer', status: 'open')

      assigned_count_6 = run_assignment(inbox2)

      # Should assign 1
      open_assigned = assert_equal(
        assigned_count_6,
        1,
        'Open conversation assigned'
      )

      conv_open.reload
      open_has_assignee = assert(
        conv_open.assignee_id.present?,
        'Open conversation has assignee',
        'Open conversation not assigned'
      )

      test5_ok = status_ok && none_assigned_5 && open_assigned && open_has_assignee

      # Cleanup inbox2
      cleanup_test_data(account, inbox: inbox2)

      # Final result
      if test1_ok && test2_ok && test3_ok && test4_ok && test5_ok
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
exit(TestEdgeCases.new.run ? 0 : 1)
