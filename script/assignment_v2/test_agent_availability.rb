# frozen_string_literal: true

# Test: Agent Availability and Status
# Run with: bundle exec rails runner script/assignment_v2/test_agent_availability.rb
#
# Tests:
# - Only online agents receive assignments
# - Offline agents are excluded from assignment pool
# - When agents go offline mid-assignment, remaining conversations go to online agents
# - When agents come online, they become eligible for new assignments
#
# Key Implementation Details:
# - inbox.available_agents filters by online status via OnlineStatusTracker
# - OnlineStatusTracker.update_presence(account_id, 'User', user_id) marks agent as online
# - OnlineStatusTracker.remove_presence(account_id, 'User', user_id) marks agent as offline
# - Availability is checked for EACH conversation assignment (not cached for the batch)
# - This ensures real-time status changes affect assignment within a single job run

require_relative 'test_helpers'

class TestAgentAvailability
  include AssignmentV2TestHelpers

  def run
    section('TEST: Agent Availability and Status')

    account = get_test_account
    inbox = nil

    begin
      # Setup test inbox and policy
      inbox = create_test_inbox(account, name: 'Availability Test Inbox')
      policy = create_test_policy(account, name: 'Availability Test Policy')
      link_policy_to_inbox(inbox, policy)

      # Test 1: Only online agents receive assignments
      section('Test 1: Only Online Agents Get Assigned')

      # Create 3 agents: 2 online, 1 offline
      agent_online_1 = create_test_agent(account, inbox, name: 'Agent Online 1', online: true)
      agent_online_2 = create_test_agent(account, inbox, name: 'Agent Online 2', online: true)
      agent_offline = create_test_agent(account, inbox, name: 'Agent Offline', online: false)

      info("Online agents: #{agent_online_1.name}, #{agent_online_2.name}")
      info("Offline agent: #{agent_offline.name}")

      # Create 6 conversations (should be split between 2 online agents only)
      create_bulk_conversations(inbox, count: 6)

      # Run assignment
      assigned_count = run_assignment(inbox)

      # Verify only online agents got assignments
      log('Verifying only online agents assigned...', color: :blue)

      # Should assign all 6 conversations (2 online agents available)
      all_assigned = assert_equal(
        assigned_count,
        6,
        'All 6 conversations assigned'
      )

      # Each online agent should have 3 conversations (round-robin between 2)
      online_1_count = inbox.conversations.where(assignee: agent_online_1).count
      online_2_count = inbox.conversations.where(assignee: agent_online_2).count
      offline_count = inbox.conversations.where(assignee: agent_offline).count

      distribution_ok = assert_equal(
        online_1_count,
        3,
        "#{agent_online_1.name} has 3 conversations"
      )

      distribution_ok &= assert_equal(
        online_2_count,
        3,
        "#{agent_online_2.name} has 3 conversations"
      )

      # Offline agent should have 0
      offline_excluded = assert_equal(
        offline_count,
        0,
        "#{agent_offline.name} has 0 conversations (offline)"
      )

      test1_ok = all_assigned && distribution_ok && offline_excluded

      # Test 2: When agent goes offline, new assignments skip them
      section('Test 2: Agent Goes Offline Mid-Test')

      # Take agent_online_2 offline by setting status to 'offline'
      OnlineStatusTracker.set_status(account.id, agent_online_2.id, 'offline')
      info("Took #{agent_online_2.name} offline")

      # Create 3 more conversations
      create_bulk_conversations(inbox, count: 3)

      # Run assignment again
      assigned_count_2 = run_assignment(inbox)

      # Verify only agent_online_1 gets the new assignments
      log('Verifying offline agent excluded...', color: :blue)

      # Should assign all 3 new conversations
      all_assigned_2 = assert_equal(
        assigned_count_2,
        3,
        'All 3 new conversations assigned'
      )

      # Agent_online_1 should now have 6 total (3 + 3 new)
      online_1_new_count = inbox.conversations.where(assignee: agent_online_1).count
      online_1_got_all = assert_equal(
        online_1_new_count,
        6,
        "#{agent_online_1.name} has 6 conversations (got all new ones)"
      )

      # Agent_online_2 should still have 3 (no new assignments)
      online_2_still_count = inbox.conversations.where(assignee: agent_online_2).count
      online_2_unchanged = assert_equal(
        online_2_still_count,
        3,
        "#{agent_online_2.name} still has 3 conversations (offline, no new ones)"
      )

      test2_ok = all_assigned_2 && online_1_got_all && online_2_unchanged

      # Test 3: When agent comes online, they become eligible
      section('Test 3: Agent Comes Online')

      # Bring agent_online_2 back online by updating presence and setting status
      OnlineStatusTracker.update_presence(account.id, 'User', agent_online_2.id)
      OnlineStatusTracker.set_status(account.id, agent_online_2.id, 'online')
      info("Brought #{agent_online_2.name} back online")

      # Bring offline agent online too
      OnlineStatusTracker.update_presence(account.id, 'User', agent_offline.id)
      OnlineStatusTracker.set_status(account.id, agent_offline.id, 'online')
      info("Brought #{agent_offline.name} online")

      # Create 6 more conversations (should distribute across all 3 now)
      create_bulk_conversations(inbox, count: 6)

      # Run assignment
      assigned_count_3 = run_assignment(inbox)

      # Verify all 3 agents get assignments
      log('Verifying all online agents get assignments...', color: :blue)

      # Should assign all 6 conversations
      all_assigned_3 = assert_equal(
        assigned_count_3,
        6,
        'All 6 final conversations assigned'
      )

      # Each agent should get 2 more (round-robin across 3)
      agent_online_1_final = inbox.conversations.where(assignee: agent_online_1).count
      agent_online_2_final = inbox.conversations.where(assignee: agent_online_2).count
      agent_offline_final = inbox.conversations.where(assignee: agent_offline).count

      online_1_increased = assert_equal(
        agent_online_1_final,
        8,  # 6 + 2
        "#{agent_online_1.name} has 8 conversations (6 + 2 new)"
      )

      online_2_increased = assert_equal(
        agent_online_2_final,
        5,  # 3 + 2
        "#{agent_online_2.name} has 5 conversations (3 + 2 new)"
      )

      # Previously offline agent should now have assignments
      previously_offline_assigned = assert_equal(
        agent_offline_final,
        2,  # 0 + 2
        "#{agent_offline.name} has 2 conversations (came online, got 2 new)"
      )

      test3_ok = all_assigned_3 && online_1_increased && online_2_increased && previously_offline_assigned

      # Show final distribution
      show_assignment_distribution(inbox, [agent_online_1, agent_online_2, agent_offline])

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
exit(TestAgentAvailability.new.run ? 0 : 1)
