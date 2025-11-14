# frozen_string_literal: true

# Test: Conversation Exclusion Rules (Enterprise)
# Run with: bundle exec rails runner script/assignment_v2/test_exclusion_rules.rb
#
# Tests:
# - Conversations with excluded labels are not assigned
# - Conversations older than threshold are not assigned
# - Multiple exclusion rules work together
# - Conversations without exclusions are assigned normally
#
# Key Implementation Details:
# - Exclusion rules are stored in AgentCapacityPolicy#exclusion_rules (JSONB)
# - exclusion_rules format: { excluded_labels: ['vip', 'escalated'], exclude_older_than_hours: 24 }
# - Enterprise::AutoAssignment::AssignmentService#apply_exclusion_rules filters conversations
# - Label exclusions use: scope.tagged_with(labels, exclude: true, on: :labels)
# - Age exclusions use: scope.where('created_at >= ?', hours.hours.ago)
# - Exclusions apply BEFORE conversations are fetched for assignment

require_relative 'test_helpers'

class TestExclusionRules
  include AssignmentV2TestHelpers

  def run
    skip_if_not_enterprise

    section('TEST: Conversation Exclusion Rules (Enterprise)')

    account = get_test_account
    inbox = nil

    begin
      # Setup test inbox and policy
      inbox = create_test_inbox(account, name: 'Exclusion Test Inbox')
      policy = create_test_policy(account, name: 'Exclusion Test Policy')
      link_policy_to_inbox(inbox, policy)

      # Test 1: Label exclusions
      section('Test 1: Exclude Conversations by Label')

      # Create agent
      create_test_agent(account, inbox, name: 'Agent Exclusion Test', online: true)

      # Create capacity policy with label exclusions
      capacity_policy = account.agent_capacity_policies.create!(
        name: "Exclusion Policy #{SecureRandom.hex(4)}",
        exclusion_rules: {
          'excluded_labels' => %w[vip escalated]
        }
      )

      # Link capacity policy to inbox
      capacity_policy.inbox_capacity_limits.create!(
        inbox: inbox,
        conversation_limit: 100  # High limit to ensure exclusions are the only filter
      )

      info('Created exclusion rule: exclude conversations with labels [vip, escalated]')

      # Create conversations: 2 with excluded labels, 2 without
      conv_vip = create_test_conversation(inbox, contact_name: 'VIP Customer')
      conv_vip.label_list.add('vip')
      conv_vip.save!

      conv_escalated = create_test_conversation(inbox, contact_name: 'Escalated Customer')
      conv_escalated.label_list.add('escalated')
      conv_escalated.save!

      conv_normal_1 = create_test_conversation(inbox, contact_name: 'Normal Customer 1')
      conv_normal_2 = create_test_conversation(inbox, contact_name: 'Normal Customer 2')

      info('Created 4 conversations: 2 with excluded labels, 2 without')

      # Run assignment
      assigned_count = run_assignment(inbox)

      # Verify only non-excluded conversations assigned
      log('Verifying label exclusions...', color: :blue)

      # Should assign only 2 conversations (the ones without excluded labels)
      correct_count = assert_equal(
        assigned_count,
        2,
        'Only 2 conversations assigned (excluded label conversations skipped)'
      )

      # VIP conversation should remain unassigned
      conv_vip.reload
      vip_excluded = assert(
        conv_vip.assignee_id.nil?,
        'VIP conversation remains unassigned',
        'VIP conversation was assigned (should be excluded)'
      )

      # Escalated conversation should remain unassigned
      conv_escalated.reload
      escalated_excluded = assert(
        conv_escalated.assignee_id.nil?,
        'Escalated conversation remains unassigned',
        'Escalated conversation was assigned (should be excluded)'
      )

      # Normal conversations should be assigned
      conv_normal_1.reload
      conv_normal_2.reload
      normals_assigned = assert(
        conv_normal_1.assignee_id.present? && conv_normal_2.assignee_id.present?,
        'Normal conversations assigned',
        'Normal conversations not assigned'
      )

      test1_ok = correct_count && vip_excluded && escalated_excluded && normals_assigned

      # Test 2: Age exclusions
      section('Test 2: Exclude Conversations by Age')

      # Clear previous test data
      inbox.conversations.destroy_all

      # Update exclusion rules to exclude conversations older than 1 hour
      capacity_policy.update!(
        exclusion_rules: {
          'exclude_older_than_hours' => 1
        }
      )
      info('Updated exclusion rule: exclude conversations older than 1 hour')

      # Create conversations: 2 old (>1 hour), 2 recent (<1 hour)
      conv_old_1 = create_test_conversation(
        inbox,
        contact_name: 'Old Customer 1',
        created_at: 2.hours.ago,
        last_activity_at: 2.hours.ago
      )

      conv_old_2 = create_test_conversation(
        inbox,
        contact_name: 'Old Customer 2',
        created_at: 90.minutes.ago,
        last_activity_at: 90.minutes.ago
      )

      conv_recent_1 = create_test_conversation(
        inbox,
        contact_name: 'Recent Customer 1',
        created_at: 30.minutes.ago,
        last_activity_at: 30.minutes.ago
      )

      conv_recent_2 = create_test_conversation(
        inbox,
        contact_name: 'Recent Customer 2',
        created_at: 10.minutes.ago,
        last_activity_at: 10.minutes.ago
      )

      info('Created 4 conversations: 2 older than 1 hour, 2 recent')

      # Run assignment
      assigned_count_2 = run_assignment(inbox)

      # Verify only recent conversations assigned
      log('Verifying age exclusions...', color: :blue)

      # Should assign only 2 conversations (the recent ones)
      correct_count_2 = assert_equal(
        assigned_count_2,
        2,
        'Only 2 conversations assigned (old conversations excluded)'
      )

      # Old conversations should remain unassigned
      conv_old_1.reload
      conv_old_2.reload
      old_excluded = assert(
        conv_old_1.assignee_id.nil? && conv_old_2.assignee_id.nil?,
        'Old conversations remain unassigned',
        'Old conversations were assigned (should be excluded)'
      )

      # Recent conversations should be assigned
      conv_recent_1.reload
      conv_recent_2.reload
      recent_assigned = assert(
        conv_recent_1.assignee_id.present? && conv_recent_2.assignee_id.present?,
        'Recent conversations assigned',
        'Recent conversations not assigned'
      )

      test2_ok = correct_count_2 && old_excluded && recent_assigned

      # Test 3: Combined exclusions (both label and age)
      section('Test 3: Combined Label and Age Exclusions')

      # Clear previous test data
      inbox.conversations.destroy_all

      # Update exclusion rules to have both label and age exclusions
      capacity_policy.update!(
        exclusion_rules: {
          'excluded_labels' => ['urgent'],
          'exclude_older_than_hours' => 1
        }
      )
      info('Updated exclusion rules: exclude [urgent] labels AND conversations older than 1 hour')

      # Create 5 conversations with different combinations
      # 1. Recent + no label = should be assigned
      conv_good = create_test_conversation(
        inbox,
        contact_name: 'Good Customer',
        created_at: 30.minutes.ago
      )

      # 2. Old + no label = excluded by age
      conv_old = create_test_conversation(
        inbox,
        contact_name: 'Old Customer',
        created_at: 2.hours.ago
      )

      # 3. Recent + urgent label = excluded by label
      conv_urgent = create_test_conversation(
        inbox,
        contact_name: 'Urgent Customer',
        created_at: 30.minutes.ago
      )
      conv_urgent.label_list.add('urgent')
      conv_urgent.save!

      # 4. Old + urgent label = excluded by both (double excluded)
      conv_double_excluded = create_test_conversation(
        inbox,
        contact_name: 'Old Urgent Customer',
        created_at: 2.hours.ago
      )
      conv_double_excluded.label_list.add('urgent')
      conv_double_excluded.save!

      # 5. Recent + normal label = should be assigned
      conv_good_2 = create_test_conversation(
        inbox,
        contact_name: 'Good Customer 2',
        created_at: 20.minutes.ago
      )
      conv_good_2.label_list.add('normal')
      conv_good_2.save!

      info('Created 5 conversations: 1 old, 1 urgent, 1 old+urgent, 2 assignable')

      # Run assignment
      assigned_count_3 = run_assignment(inbox)

      # Verify combined exclusions
      log('Verifying combined exclusions...', color: :blue)

      # Should assign only 2 conversations (the ones passing both filters)
      correct_count_3 = assert_equal(
        assigned_count_3,
        2,
        'Only 2 conversations assigned (combined exclusions work)'
      )

      # Excluded conversations should remain unassigned
      conv_old.reload
      conv_urgent.reload
      conv_double_excluded.reload
      all_excluded = assert(
        conv_old.assignee_id.nil? &&
        conv_urgent.assignee_id.nil? &&
        conv_double_excluded.assignee_id.nil?,
        'All excluded conversations remain unassigned',
        'Some excluded conversations were assigned'
      )

      # Good conversations should be assigned
      conv_good.reload
      conv_good_2.reload
      good_assigned = assert(
        conv_good.assignee_id.present? && conv_good_2.assignee_id.present?,
        'Valid conversations assigned',
        'Valid conversations not assigned'
      )

      test3_ok = correct_count_3 && all_excluded && good_assigned

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
exit(TestExclusionRules.new.run ? 0 : 1)
