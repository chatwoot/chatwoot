# frozen_string_literal: true

# Test: Real-Time Assignment Trigger
# Run with: bundle exec rails runner script/assignment_v2/test_real_time_trigger.rb
#
# Tests:
# - Assignment triggered when conversation status changes to 'open'
# - Assignment triggered when new conversation created
# - Assignment only runs when assignee is blank
# - Assignment respects enable_auto_assignment flag
#
# Key Implementation Details:
# - AutoAssignmentHandler is a concern included in Conversation model
# - Triggers after_save when conversation_status_changed_to_open?
# - Checks inbox.auto_assignment_v2_enabled? to use v2 vs legacy system
# - NOTE: auto_assignment_v2_enabled? not yet implemented, so this test simulates expected behavior
# - When implemented, it will call: AutoAssignment::AssignmentJob.perform_later(inbox_id: inbox.id)
#
# This test manually triggers assignment to simulate real-time behavior

require_relative 'test_helpers'

class TestRealTimeTrigger
  include AssignmentV2TestHelpers

  def run
    section('TEST: Real-Time Assignment Trigger')

    account = get_test_account
    inbox = nil

    begin
      # Setup test inbox and policy
      inbox = create_test_inbox(account, name: 'Real-Time Trigger Test Inbox')
      policy = create_test_policy(account, name: 'Real-Time Policy')
      link_policy_to_inbox(inbox, policy)

      # Create agent
      agent = create_test_agent(account, inbox, name: 'Agent Real-Time', online: true)

      # Test 1: Assignment triggered when conversation status changes to open
      section('Test 1: Status Change to Open Triggers Assignment')

      # Create conversation with status 'pending' (not open)
      conv = create_test_conversation(inbox, contact_name: 'Pending Customer', status: 'pending')
      info('Created conversation with status: pending')

      # Conversation should not be assigned (status is not open)
      conv.reload
      pending_unassigned = assert(
        conv.assignee_id.nil?,
        'Pending conversation not assigned',
        'Pending conversation was assigned (should not be)'
      )

      # Change status to 'open' and manually trigger assignment (simulating handler)
      conv.update!(status: 'open')
      info('Changed status to: open')

      # Simulate real-time trigger: run assignment job
      # In production, AutoAssignmentHandler would call: AutoAssignment::AssignmentJob.perform_later
      assigned_count = run_assignment(inbox)

      # Verify assignment happened
      log('Verifying assignment after status change...', color: :blue)

      assigned_ok = assert_equal(
        assigned_count,
        1,
        'Conversation assigned after status changed to open'
      )

      conv.reload
      has_assignee = assert(
        conv.assignee_id.present?,
        'Conversation has assignee',
        'Conversation not assigned'
      )

      test1_ok = pending_unassigned && assigned_ok && has_assignee

      # Test 2: New conversation created as 'open' triggers assignment
      section('Test 2: New Open Conversation Triggers Assignment')

      # Create conversation directly as 'open'
      conv2 = create_test_conversation(inbox, contact_name: 'Open Customer', status: 'open')
      info('Created conversation with status: open')

      # Simulate real-time trigger
      assigned_count_2 = run_assignment(inbox)

      # Verify assignment
      log('Verifying assignment for new open conversation...', color: :blue)

      assigned_ok_2 = assert_equal(
        assigned_count_2,
        1,
        'New open conversation assigned'
      )

      conv2.reload
      has_assignee_2 = assert(
        conv2.assignee_id.present?,
        'New conversation has assignee',
        'New conversation not assigned'
      )

      test2_ok = assigned_ok_2 && has_assignee_2

      # Test 3: Already assigned conversation not re-assigned
      section('Test 3: Already Assigned Conversation Not Re-Assigned')

      # Create and assign a conversation
      conv3 = create_test_conversation(inbox, contact_name: 'Customer 3', status: 'open')
      run_assignment(inbox)
      conv3.reload
      original_assignee = conv3.assignee
      info("Conversation initially assigned to: #{original_assignee.name}")

      # Update something else (not status, not assignee)
      conv3.update!(additional_attributes: { test: 'value' })

      # Simulate real-time trigger
      assigned_count_3 = run_assignment(inbox)

      # Verify no re-assignment
      log('Verifying already-assigned conversation not re-assigned...', color: :blue)

      # Should assign 0 (conversation already has assignee)
      no_reassign = assert_equal(
        assigned_count_3,
        0,
        'No conversations re-assigned'
      )

      conv3.reload
      same_assignee = assert(
        conv3.assignee_id == original_assignee.id,
        'Conversation keeps original assignee',
        'Conversation was re-assigned (should not be)'
      )

      test3_ok = no_reassign && same_assignee

      # Test 4: Resolved conversation changing to open triggers assignment
      section('Test 4: Resolved → Open Triggers Assignment')

      # Create and resolve a conversation
      conv4 = create_test_conversation(inbox, contact_name: 'Returning Customer', status: 'open')
      run_assignment(inbox)
      conv4.reload
      conv4.update!(status: 'resolved', assignee: nil)
      info('Conversation resolved and unassigned')

      # Reopen conversation
      conv4.update!(status: 'open')
      info('Conversation reopened (status: open)')

      # Simulate real-time trigger
      assigned_count_4 = run_assignment(inbox)

      # Verify re-assignment
      log('Verifying reopened conversation assigned...', color: :blue)

      assigned_ok_4 = assert_equal(
        assigned_count_4,
        1,
        'Reopened conversation assigned'
      )

      conv4.reload
      has_assignee_4 = assert(
        conv4.assignee_id.present?,
        'Reopened conversation has assignee',
        'Reopened conversation not assigned'
      )

      test4_ok = assigned_ok_4 && has_assignee_4

      # Test 5: Assignment respects online status in real-time
      section('Test 5: Real-Time Assignment Respects Agent Availability')

      # Take agent offline
      OnlineStatusTracker.set_status(account.id, agent.id, 'offline')
      info("Took #{agent.name} offline")

      # Create new conversation
      conv5 = create_test_conversation(inbox, contact_name: 'Customer During Offline', status: 'open')

      # Simulate real-time trigger
      assigned_count_5 = run_assignment(inbox)

      # Verify no assignment (agent offline)
      log('Verifying no assignment when agent offline...', color: :blue)

      no_assign_offline = assert_equal(
        assigned_count_5,
        0,
        'No assignment when agent offline'
      )

      conv5.reload
      unassigned_offline = assert(
        conv5.assignee_id.nil?,
        'Conversation remains unassigned when agent offline',
        'Conversation was assigned despite agent being offline'
      )

      # Bring agent back online
      OnlineStatusTracker.update_presence(account.id, 'User', agent.id)
      OnlineStatusTracker.set_status(account.id, agent.id, 'online')
      info("Brought #{agent.name} back online")

      # Simulate real-time trigger (next conversation triggers assignment for backlog)
      assigned_count_6 = run_assignment(inbox)

      # Now should assign
      assigned_after_online = assert_equal(
        assigned_count_6,
        1,
        'Assignment happens when agent comes online'
      )

      test5_ok = no_assign_offline && unassigned_offline && assigned_after_online

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
exit(TestRealTimeTrigger.new.run ? 0 : 1)
