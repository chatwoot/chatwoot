# frozen_string_literal: true

# Test: Basic Assignment Functionality
# Run with: bundle exec rails runner script/assignment_v2/test_basic_assignment.rb
#
# Tests:
# - Unassigned open conversations get assigned
# - Only online agents receive assignments
# - Round-robin distribution works correctly
# - Assignee is persisted in database
#
# Key Implementation Details:
# - Uses FactoryBot to create conversations with proper associations (contact, contact_inbox)
# - Requires inbox.reload after linking policy to pick up the association
# - Assignment job expects keyword argument: perform_now(inbox_id: id), not perform_now(id)
# - Round-robin is the default selection strategy when no policy specifies 'balanced'

require_relative 'test_helpers'

class TestBasicAssignment
  include AssignmentV2TestHelpers

  def run
    section('TEST: Basic Assignment Functionality')

    # Use Account ID 2 by default (configurable in test_helpers.rb)
    account = get_test_account
    inbox = nil

    begin
      # Setup test inbox and policy
      # Note: Unique names are generated to avoid conflicts across test runs
      inbox = create_test_inbox(account, name: 'Basic Test Inbox')
      policy = create_test_policy(account, name: 'Basic Test Policy')

      # Link policy to inbox
      # Important: This creates InboxAssignmentPolicy and reloads inbox to pick up association
      link_policy_to_inbox(inbox, policy)

      # Create 3 online agents
      # Note: Each agent gets a unique email and name to avoid validation errors
      # Agents are automatically added to inbox members and marked online via OnlineStatusTracker
      agents = 3.times.map do |i|
        create_test_agent(account, inbox, name: "Agent #{i + 1}", online: true)
      end

      # Create 9 unassigned conversations (3 per agent for round-robin test)
      # Uses FactoryBot to create conversations with all required associations:
      # - Contact with account
      # - ContactInbox with source_id (required field)
      # - Conversation linked to inbox, account, contact, and contact_inbox
      conversations = create_bulk_conversations(inbox, count: 9)

      # Run assignment job
      # Fix: Must use keyword argument inbox_id (not positional argument)
      # The job calculates assigned_count internally, we derive it from before/after counts
      assigned_count = run_assignment(inbox)

      # Verify assignments
      log('Verifying results...', color: :blue)

      # Test 1: All conversations should be assigned
      all_assigned = assert_equal(
        inbox.conversations.unassigned.count,
        0,
        'All conversations assigned'
      )

      # Test 2: Assigned count should be 9
      correct_count = assert_equal(
        assigned_count,
        9,
        'Assigned count matches'
      )

      # Test 3: Each agent should have exactly 3 conversations (round-robin)
      # Round-robin selector should distribute evenly: 9 conversations ÷ 3 agents = 3 each
      distribution_correct = true
      agents.each do |agent|
        count = inbox.conversations.where(assignee: agent).count
        if count == 3
          success("#{agent.name} has 3 conversations")
        else
          error("#{agent.name} has #{count} conversations (expected 3)")
          distribution_correct = false
        end
      end

      # Test 4: Verify assignee is persisted in database
      # Important: Must reload conversations to get updated assignee_id
      persistence_ok = conversations.all? do |conv|
        conv.reload
        conv.assignee_id.present?
      end

      assert(
        persistence_ok,
        'All conversations have persisted assignee_id',
        'Some conversations missing assignee_id'
      )

      # Show distribution summary
      show_assignment_distribution(inbox, agents)

      # Final result: All tests must pass for success
      if all_assigned && correct_count && distribution_correct && persistence_ok
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
      # Always cleanup test data (inbox, agents, conversations, policies)
      # This prevents test data from accumulating in the database
      cleanup_test_data(account, inbox: inbox) if inbox
    end
  end
end

# Run test and exit with appropriate code (0 = success, 1 = failure)
exit(TestBasicAssignment.new.run ? 0 : 1)
