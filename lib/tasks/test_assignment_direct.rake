# frozen_string_literal: true

namespace :test do
  desc "Test direct assignment of unassigned conversations"
  task test_direct_assignment: :environment do
    puts "🚀 Testing direct assignment functionality..."
    puts "=" * 60
    
    # Get the first account
    account = Account.first
    unless account
      puts "❌ No account found. Please create an account first."
      exit
    end
    
    # Get the first inbox
    inbox = account.inboxes.first
    unless inbox
      puts "❌ No inbox found. Please create an inbox first."
      exit
    end
    
    puts "📊 Using:"
    puts "  Account: #{account.name} (ID: #{account.id})"
    puts "  Inbox: #{inbox.name} (ID: #{inbox.id})"
    puts "  Channel Type: #{inbox.channel_type}"
    puts "-" * 60
    
    # Check assignment configuration
    puts "\n🔧 Assignment Configuration:"
    puts "  Assignment V2 enabled: #{inbox.assignment_v2_enabled?}"
    puts "  Auto assignment enabled: #{inbox.enable_auto_assignment}"
    
    if inbox.assignment_v2_enabled?
      if inbox.assignment_policy
        puts "  Assignment Policy: #{inbox.assignment_policy.name}"
        puts "    - Order: #{inbox.assignment_policy.assignment_order}"
        puts "    - Priority: #{inbox.assignment_policy.conversation_priority}"
        puts "    - Enabled: #{inbox.assignment_policy.enabled?}"
      else
        puts "  ⚠️  No assignment policy configured for this inbox"
      end
    end
    
    # Get available agents
    puts "\n👥 Available Agents:"
    agents = inbox.members
    if agents.empty?
      puts "  ❌ No agents assigned to this inbox"
      exit
    end
    
    agents.each do |agent|
      puts "  - #{agent.name} (#{agent.email}) - ID: #{agent.id}"
    end
    
    # Get unassigned conversations
    puts "\n💬 Unassigned Conversations:"
    unassigned_conversations = inbox.conversations.unassigned.open
    
    if unassigned_conversations.empty?
      puts "  ❌ No unassigned conversations found"
      puts "\n  Creating test conversations..."
      
      # Create some test conversations
      contact = inbox.contacts.first || create_test_contact(account, inbox)
      
      3.times do |i|
        conversation = inbox.conversations.create!(
          account: account,
          contact: contact,
          status: 'open',
          additional_attributes: { test: true, created_by: 'assignment_test' }
        )
        puts "    ✅ Created conversation ##{conversation.display_id}"
      end
      
      unassigned_conversations = inbox.conversations.unassigned.open
    end
    
    puts "  Found #{unassigned_conversations.count} unassigned conversations"
    unassigned_conversations.limit(5).each do |conv|
      puts "    - Conversation ##{conv.display_id} (Created: #{conv.created_at})"
    end
    
    # Test Assignment Methods
    puts "\n🧪 Testing Assignment Methods:"
    puts "-" * 60
    
    # Method 1: Using Legacy Auto Assignment Service
    puts "\n1️⃣ Testing Legacy Auto Assignment Service:"
    test_legacy_assignment(unassigned_conversations.first, inbox)
    
    # Method 2: Using Assignment V2 Service (if enabled)
    if inbox.assignment_v2_enabled?
      puts "\n2️⃣ Testing Assignment V2 Service:"
      test_assignment_v2(inbox)
    else
      puts "\n2️⃣ Assignment V2 is not enabled for this inbox"
      puts "   To enable, you need to configure assignment_v2 in GlobalConfig"
    end
    
    # Method 3: Direct assignment using conversation model
    puts "\n3️⃣ Testing Direct Assignment via Conversation Model:"
    test_direct_conversation_assignment(unassigned_conversations.second, agents.first)
    
    # Show final status
    puts "\n📊 Final Status:"
    puts "  Total conversations: #{inbox.conversations.count}"
    puts "  Assigned: #{inbox.conversations.assigned.count}"
    puts "  Unassigned: #{inbox.conversations.unassigned.count}"
    
    puts "\n✅ Assignment test completed!"
  end
  
  private
  
  def create_test_contact(account, inbox)
    contact = account.contacts.create!(
      name: "Test Contact #{Time.current.to_i}",
      email: "test#{Time.current.to_i}@example.com"
    )
    
    inbox.contact_inboxes.create!(
      contact: contact,
      source_id: "test_#{Time.current.to_i}"
    )
    
    contact
  end
  
  def test_legacy_assignment(conversation, inbox)
    return unless conversation
    
    puts "  Testing on conversation ##{conversation.display_id}..."
    
    # Get available agents with capacity
    agent_ids = inbox.member_ids_with_assignment_capacity
    puts "  Agents with capacity: #{agent_ids.inspect}"
    
    # Use the legacy assignment service
    service = ::AutoAssignment::AgentAssignmentService.new(
      conversation: conversation,
      allowed_agent_ids: agent_ids
    )
    
    # Find assignee using round robin
    assignee = service.find_assignee
    if assignee
      puts "  ✅ Found assignee: #{assignee.name} (ID: #{assignee.id})"
      
      # Perform the assignment
      service.perform
      
      # Reload and verify
      conversation.reload
      if conversation.assignee
        puts "  ✅ Successfully assigned to: #{conversation.assignee.name}"
      else
        puts "  ❌ Assignment failed"
      end
    else
      puts "  ❌ No available agent found for assignment"
      puts "     This could be because all agents are offline or at capacity"
    end
  end
  
  def test_assignment_v2(inbox)
    service = AssignmentV2::AssignmentService.new(inbox: inbox)
    
    # Try bulk assignment
    assigned_count = service.perform_bulk_assignment(limit: 2)
    
    puts "  ✅ Assigned #{assigned_count} conversations using Assignment V2"
    
    # Show which conversations were assigned
    recent_assignments = inbox.conversations.assigned.order(updated_at: :desc).limit(assigned_count)
    recent_assignments.each do |conv|
      puts "    - Conversation ##{conv.display_id} → #{conv.assignee.name}"
    end
  end
  
  def test_direct_conversation_assignment(conversation, agent)
    return unless conversation && agent
    
    puts "  Assigning conversation ##{conversation.display_id} to #{agent.name}..."
    
    # Direct assignment
    conversation.update!(assignee: agent)
    
    # Verify
    conversation.reload
    if conversation.assignee == agent
      puts "  ✅ Successfully assigned directly"
    else
      puts "  ❌ Direct assignment failed"
    end
  end
end