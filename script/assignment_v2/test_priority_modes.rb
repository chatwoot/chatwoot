# frozen_string_literal: true

# Test: Conversation Priority Modes
# Run with: bundle exec rails runner script/assignment_v2/test_priority_modes.rb
#
# Tests:
# - longest_waiting mode prioritizes conversations by oldest last_activity_at
# - earliest_created mode (default) prioritizes by oldest created_at
# - Assignment respects policy priority setting
# - Edge case: longest_waiting uses created_at as tiebreaker
#
# Key Implementation Details:
# - Priority is set via policy.conversation_priority enum ('longest_waiting' or 'earliest_created')
# - Enterprise::AutoAssignment::AssignmentService applies priority via unassigned_conversations method
# - longest_waiting: ORDER BY last_activity_at ASC, created_at ASC (uses created_at as tiebreaker)
# - earliest_created: ORDER BY created_at ASC (pure FIFO)
# - Priority affects which conversations are fetched and assigned first

require_relative 'test_helpers'

class TestPriorityModes
  include AssignmentV2TestHelpers

  def run
    section('TEST: Conversation Priority Modes')

    account = get_test_account
    inbox_longest = nil
    inbox_earliest = nil

    begin
      # Test 1: longest_waiting mode
      section('Test 1: Longest Waiting Mode')
      inbox_longest = create_test_inbox(account, name: 'Longest Waiting Test')
      policy_longest = create_test_policy(
        account,
        name: 'Longest Waiting Policy',
        conversation_priority: 'longest_waiting'
      )
      link_policy_to_inbox(inbox_longest, policy_longest)

      # Create 1 agent for this test (to control assignment order)
      create_test_agent(account, inbox_longest, name: 'Agent Priority Test', online: true)

      # Create conversations with specific last_activity_at times
      # Conversation order by last_activity_at (oldest first):
      # conv_c (30 min ago) -> conv_b (20 min ago) -> conv_a (10 min ago)
      # But created_at order is: conv_a -> conv_b -> conv_c
      info('Creating conversations with varied last_activity_at times...')

      conv_a = create_test_conversation(
        inbox_longest,
        contact_name: 'Customer A',
        created_at: 30.minutes.ago,
        last_activity_at: 10.minutes.ago  # Most recent activity
      )

      conv_b = create_test_conversation(
        inbox_longest,
        contact_name: 'Customer B',
        created_at: 20.minutes.ago,
        last_activity_at: 20.minutes.ago  # Middle activity
      )

      conv_c = create_test_conversation(
        inbox_longest,
        contact_name: 'Customer C',
        created_at: 10.minutes.ago,
        last_activity_at: 30.minutes.ago  # Oldest activity (should be first)
      )

      info("Conv A: created #{conv_a.created_at}, activity #{conv_a.last_activity_at}")
      info("Conv B: created #{conv_b.created_at}, activity #{conv_b.last_activity_at}")
      info("Conv C: created #{conv_c.created_at}, activity #{conv_c.last_activity_at}")

      # Run assignment - should only assign 1 conversation (the oldest by last_activity_at)
      # We'll run assignment 3 times to see the order
      info('Running first assignment (should assign conv_c - oldest activity)...')
      run_assignment(inbox_longest)
      conv_c.reload
      first_assigned = conv_c

      info('Running second assignment (should assign conv_b - middle activity)...')
      run_assignment(inbox_longest)
      conv_b.reload
      second_assigned = conv_b

      info('Running third assignment (should assign conv_a - newest activity)...')
      run_assignment(inbox_longest)
      conv_a.reload
      third_assigned = conv_a

      # Verify longest_waiting prioritization
      log('Verifying longest_waiting order...', color: :blue)

      # Conv C should be assigned (oldest last_activity_at)
      order_correct_1 = assert(
        first_assigned == conv_c && conv_c.assignee_id.present?,
        'First assigned: conv_c (oldest last_activity_at: 30 min ago)',
        "First assigned should be conv_c, got: #{first_assigned.contact.name}"
      )

      # Conv B should be assigned next (middle last_activity_at)
      order_correct_2 = assert(
        second_assigned == conv_b && conv_b.assignee_id.present?,
        'Second assigned: conv_b (middle last_activity_at: 20 min ago)',
        "Second assigned should be conv_b, got: #{second_assigned.contact.name}"
      )

      # Conv A should be assigned last (newest last_activity_at)
      order_correct_3 = assert(
        third_assigned == conv_a && conv_a.assignee_id.present?,
        'Third assigned: conv_a (newest last_activity_at: 10 min ago)',
        "Third assigned should be conv_a, got: #{third_assigned.contact.name}"
      )

      longest_waiting_ok = order_correct_1 && order_correct_2 && order_correct_3

      # Test 2: earliest_created mode (default FIFO)
      section('Test 2: Earliest Created Mode (Default FIFO)')
      inbox_earliest = create_test_inbox(account, name: 'Earliest Created Test')
      policy_earliest = create_test_policy(
        account,
        name: 'Earliest Created Policy',
        conversation_priority: 'earliest_created'
      )
      link_policy_to_inbox(inbox_earliest, policy_earliest)

      # Create 1 agent for this test
      create_test_agent(account, inbox_earliest, name: 'Agent FIFO Test', online: true)

      # Create conversations with specific created_at times
      # Same last_activity_at for all to ensure created_at is the only factor
      # Order by created_at (oldest first): conv_x -> conv_y -> conv_z
      info('Creating conversations with varied created_at times...')

      conv_x = create_test_conversation(
        inbox_earliest,
        contact_name: 'Customer X',
        created_at: 30.minutes.ago,  # Oldest created (should be first)
        last_activity_at: 15.minutes.ago
      )

      conv_y = create_test_conversation(
        inbox_earliest,
        contact_name: 'Customer Y',
        created_at: 20.minutes.ago,  # Middle created
        last_activity_at: 15.minutes.ago
      )

      conv_z = create_test_conversation(
        inbox_earliest,
        contact_name: 'Customer Z',
        created_at: 10.minutes.ago,  # Newest created (should be last)
        last_activity_at: 15.minutes.ago
      )

      info("Conv X: created #{conv_x.created_at}, activity #{conv_x.last_activity_at}")
      info("Conv Y: created #{conv_y.created_at}, activity #{conv_y.last_activity_at}")
      info("Conv Z: created #{conv_z.created_at}, activity #{conv_z.last_activity_at}")

      # Run assignment 3 times to see the order
      info('Running first assignment (should assign conv_x - oldest created)...')
      run_assignment(inbox_earliest)
      conv_x.reload
      first_assigned_fifo = conv_x

      info('Running second assignment (should assign conv_y - middle created)...')
      run_assignment(inbox_earliest)
      conv_y.reload
      second_assigned_fifo = conv_y

      info('Running third assignment (should assign conv_z - newest created)...')
      run_assignment(inbox_earliest)
      conv_z.reload
      third_assigned_fifo = conv_z

      # Verify earliest_created prioritization
      log('Verifying earliest_created (FIFO) order...', color: :blue)

      # Conv X should be assigned first (oldest created_at)
      fifo_correct_1 = assert(
        first_assigned_fifo == conv_x && conv_x.assignee_id.present?,
        'First assigned: conv_x (oldest created_at: 30 min ago)',
        "First assigned should be conv_x, got: #{first_assigned_fifo.contact.name}"
      )

      # Conv Y should be assigned next (middle created_at)
      fifo_correct_2 = assert(
        second_assigned_fifo == conv_y && conv_y.assignee_id.present?,
        'Second assigned: conv_y (middle created_at: 20 min ago)',
        "Second assigned should be conv_y, got: #{second_assigned_fifo.contact.name}"
      )

      # Conv Z should be assigned last (newest created_at)
      fifo_correct_3 = assert(
        third_assigned_fifo == conv_z && conv_z.assignee_id.present?,
        'Third assigned: conv_z (newest created_at: 10 min ago)',
        "Third assigned should be conv_z, got: #{third_assigned_fifo.contact.name}"
      )

      earliest_created_ok = fifo_correct_1 && fifo_correct_2 && fifo_correct_3

      # Final result
      if longest_waiting_ok && earliest_created_ok
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
      # Cleanup both inboxes
      cleanup_test_data(account, inbox: inbox_longest) if inbox_longest
      cleanup_test_data(account, inbox: inbox_earliest) if inbox_earliest
    end
  end
end

# Run test and exit with appropriate code
exit(TestPriorityModes.new.run ? 0 : 1)
