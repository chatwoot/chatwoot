namespace :test do
  desc "Generate comprehensive assignment test data with multiple scenarios"
  task generate_comprehensive_assignment_data: :environment do
    puts "🚀 Generating comprehensive test data for assignment functionality..."
    
    account = Account.first
    unless account
      puts "❌ No account found. Please create an account first."
      exit
    end
    
    # Note about Assignment V2
    puts "\n📝 Note: Assignment V2 requires configuration at the system level."
    puts "   For this test, we'll demonstrate policy behavior with direct assignment."
    
    # Clear existing test data first
    puts "\n🧹 Clearing existing test data..."
    clear_test_data(account)

    inbox = account.inboxes.first
    unless inbox
      puts "❌ No inbox found. Please create an inbox first."
      exit
    end

    puts "\n📊 Current Setup:"
    puts "Account: #{account.name} (ID: #{account.id})"
    puts "Inbox: #{inbox.name} (ID: #{inbox.id})"
    puts "Channel Type: #{inbox.channel_type}"
    puts "-" * 50

    # Step 1: Create more test agents
    puts "\n👥 Setting up agents..."
    agents = ensure_comprehensive_test_agents(account)
    
    # Step 2: Add all agents to the inbox
    puts "\n📥 Adding agents to inbox..."
    add_agents_to_inbox(inbox, agents)
    
    # Step 3: Create comprehensive assignment policies
    puts "\n📋 Creating assignment policies..."
    policies = create_comprehensive_assignment_policies(account, inbox)
    
    # Step 4: Create agent capacity policies
    puts "\n⚖️ Creating agent capacity policies..."
    capacity_policies = create_comprehensive_capacity_policies(account, inbox, agents)
    
    # Step 5: Create test conversations with various scenarios
    puts "\n💬 Creating test conversations..."
    conversations = create_scenario_based_conversations(account, inbox)
    
    # Step 6: Assign some conversations to test capacity
    puts "\n🔄 Assigning some conversations to test capacity..."
    assign_test_conversations(conversations, agents)
    
    puts "\n✅ Test data generation complete!"
    puts "\n📈 Summary:"
    puts "- Agents: #{agents.count}"
    puts "- Agents in Inbox: #{inbox.inbox_members.count}"
    puts "- Assignment Policies: #{policies.count}"
    puts "- Capacity Policies: #{capacity_policies.count}"
    puts "- Total Conversations: #{conversations.count}"
    puts "- Unassigned Conversations: #{inbox.conversations.unassigned.count}"
    puts "- Assigned Conversations: #{inbox.conversations.assigned.count}"
  end

  def ensure_comprehensive_test_agents(account)
    agents = []
    
    # Create test agents with different roles and experience levels
    test_agents_data = [
      # Junior Agents
      { name: "Alice Johnson", email: "alice@test.com", role: "agent", level: "junior" },
      { name: "Bob Smith", email: "bob@test.com", role: "agent", level: "junior" },
      { name: "Charlie Davis", email: "charlie@test.com", role: "agent", level: "junior" },
      
      # Mid-level Agents
      { name: "Diana Wilson", email: "diana@test.com", role: "agent", level: "mid" },
      { name: "Eve Martinez", email: "eve@test.com", role: "agent", level: "mid" },
      { name: "Frank Brown", email: "frank@test.com", role: "agent", level: "mid" },
      
      # Senior Agents
      { name: "Grace Lee", email: "grace@test.com", role: "agent", level: "senior" },
      { name: "Henry Chen", email: "henry@test.com", role: "agent", level: "senior" },
      
      # Specialist Agents
      { name: "Iris Kumar", email: "iris@test.com", role: "agent", level: "specialist" },
      { name: "Jack Wilson", email: "jack@test.com", role: "agent", level: "specialist" },
      
      # Team Leads
      { name: "Karen Miller", email: "karen@test.com", role: "administrator", level: "lead" },
      { name: "Leo Garcia", email: "leo@test.com", role: "administrator", level: "lead" }
    ]
    
    test_agents_data.each do |agent_data|
      user = User.find_or_create_by!(email: agent_data[:email]) do |u|
        u.name = agent_data[:name]
        u.password = "Password123!"
        u.password_confirmation = "Password123!"
      end
      
      # Update custom attributes
      user.custom_attributes ||= {}
      user.custom_attributes['level'] = agent_data[:level]
      user.custom_attributes['test_agent'] = true
      user.save!
      
      # Add to account if not already added
      account_user = account.account_users.find_or_create_by!(user: user) do |au|
        au.role = agent_data[:role]
      end
      
      # Update role if changed
      if account_user.role != agent_data[:role]
        account_user.update!(role: agent_data[:role])
      end
      
      agents << user
      puts "  ✓ Agent: #{user.name} (#{agent_data[:level]})"
    end
    
    agents
  end

  def add_agents_to_inbox(inbox, agents)
    agents.each do |agent|
      inbox_member = inbox.inbox_members.find_or_create_by!(user: agent)
      puts "  ✓ Added #{agent.name} to #{inbox.name}"
    end
  end

  def create_comprehensive_assignment_policies(account, inbox)
    policies = []
    
    # Policy 1: Standard Round Robin
    policy1 = account.assignment_policies.find_or_create_by!(
      name: "Standard Round Robin"
    ) do |p|
      p.description = "Basic round-robin distribution for all conversations"
      p.assignment_order = "round_robin"
      p.conversation_priority = "longest_waiting"
      p.enabled = true
      p.fair_distribution_limit = 10
      p.fair_distribution_window = 3600
    end
    policies << policy1
    puts "  ✓ Policy: #{policy1.name}"
    
    # Policy 2: Priority First Response
    policy2 = account.assignment_policies.find_or_create_by!(
      name: "Priority First Response"
    ) do |p|
      p.description = "Prioritizes earliest created conversations with tight limits"
      p.assignment_order = "round_robin"
      p.conversation_priority = "earliest_created"
      p.enabled = true
      p.fair_distribution_limit = 3
      p.fair_distribution_window = 900 # 15 minutes
    end
    policies << policy2
    puts "  ✓ Policy: #{policy2.name}"
    
    # Policy 3: High Volume Support
    policy3 = account.assignment_policies.find_or_create_by!(
      name: "High Volume Support"
    ) do |p|
      p.description = "Handles high volume with generous limits"
      p.assignment_order = "round_robin"
      p.conversation_priority = "longest_waiting"
      p.enabled = true
      p.fair_distribution_limit = 30
      p.fair_distribution_window = 7200 # 2 hours
    end
    policies << policy3
    puts "  ✓ Policy: #{policy3.name}"
    
    # Policy 4: Burst Traffic Handler
    policy4 = account.assignment_policies.find_or_create_by!(
      name: "Burst Traffic Handler"
    ) do |p|
      p.description = "Handles sudden traffic bursts with very high limits"
      p.assignment_order = "round_robin"
      p.conversation_priority = "earliest_created"
      p.enabled = false
      p.fair_distribution_limit = 50
      p.fair_distribution_window = 3600
    end
    policies << policy4
    puts "  ✓ Policy: #{policy4.name}"
    
    # Policy 5: Weekend Skeleton Crew
    policy5 = account.assignment_policies.find_or_create_by!(
      name: "Weekend Skeleton Crew"
    ) do |p|
      p.description = "Conservative assignment for limited weekend staff"
      p.assignment_order = "round_robin"
      p.conversation_priority = "longest_waiting"
      p.enabled = false
      p.fair_distribution_limit = 5
      p.fair_distribution_window = 1800 # 30 minutes
    end
    policies << policy5
    puts "  ✓ Policy: #{policy5.name}"
    
    # Policy 6: Night Shift Policy
    policy6 = account.assignment_policies.find_or_create_by!(
      name: "Night Shift Policy"
    ) do |p|
      p.description = "Balanced assignment for night shift operations"
      p.assignment_order = "round_robin"
      p.conversation_priority = "earliest_created"
      p.enabled = false
      p.fair_distribution_limit = 15
      p.fair_distribution_window = 3600
    end
    policies << policy6
    puts "  ✓ Policy: #{policy6.name}"
    
    # Policy 7: Training Mode
    policy7 = account.assignment_policies.find_or_create_by!(
      name: "Training Mode"
    ) do |p|
      p.description = "Limited assignment for agents in training"
      p.assignment_order = "round_robin"
      p.conversation_priority = "longest_waiting"
      p.enabled = false
      p.fair_distribution_limit = 2
      p.fair_distribution_window = 1800
    end
    policies << policy7
    puts "  ✓ Policy: #{policy7.name}"
    
    # Policy 8: Peak Hours Policy
    policy8 = account.assignment_policies.find_or_create_by!(
      name: "Peak Hours Policy"
    ) do |p|
      p.description = "Optimized for peak business hours"
      p.assignment_order = "round_robin"
      p.conversation_priority = "earliest_created"
      p.enabled = false
      p.fair_distribution_limit = 20
      p.fair_distribution_window = 2700 # 45 minutes
    end
    policies << policy8
    puts "  ✓ Policy: #{policy8.name}"
    
    # Associate first enabled policy with inbox
    enabled_policy = policies.find(&:enabled)
    if enabled_policy
      if inbox.inbox_assignment_policy
        inbox.inbox_assignment_policy.update!(assignment_policy: enabled_policy)
      else
        InboxAssignmentPolicy.create!(
          inbox: inbox,
          assignment_policy: enabled_policy
        )
      end
      puts "  ✓ Associated #{enabled_policy.name} with #{inbox.name}"
    end
    
    policies
  end

  def create_comprehensive_capacity_policies(account, inbox, agents)
    return [] unless defined?(Enterprise::AgentCapacityPolicy)
    
    policies = []
    
    # Group agents by level
    junior_agents = agents.select { |a| a.custom_attributes&.dig('level') == 'junior' }
    mid_agents = agents.select { |a| a.custom_attributes&.dig('level') == 'mid' }
    senior_agents = agents.select { |a| a.custom_attributes&.dig('level') == 'senior' }
    specialist_agents = agents.select { |a| a.custom_attributes&.dig('level') == 'specialist' }
    lead_agents = agents.select { |a| a.custom_attributes&.dig('level') == 'lead' }
    
    # Capacity Policy 1: Junior Agent Training
    policy1 = Enterprise::AgentCapacityPolicy.find_or_create_by!(
      account: account,
      name: "Junior Agent Training Capacity"
    ) do |p|
      p.description = "Very limited capacity for agents in training (3 conversations max)"
      p.exclusion_rules = {
        labels: ["training", "complex", "escalated", "vip"],
        hours_threshold: 72
      }
    end
    
    # Assign junior agents
    junior_agents.each do |agent|
      Enterprise::AgentCapacityPolicyUser.find_or_create_by!(
        agent_capacity_policy: policy1,
        user: agent
      )
    end
    
    # Set inbox limit
    Enterprise::InboxCapacityLimit.find_or_create_by!(
      agent_capacity_policy: policy1,
      inbox: inbox
    ) do |limit|
      limit.conversation_limit = 3
    end
    
    policies << policy1
    puts "  ✓ Capacity Policy: #{policy1.name} (#{junior_agents.count} agents, limit: 3)"
    
    # Capacity Policy 2: Standard Agent Capacity
    policy2 = Enterprise::AgentCapacityPolicy.find_or_create_by!(
      account: account,
      name: "Standard Agent Capacity"
    ) do |p|
      p.description = "Standard capacity for regular agents (10 conversations max)"
      p.exclusion_rules = {
        labels: ["escalated", "executive"],
        hours_threshold: 48
      }
    end
    
    # Assign mid-level agents
    mid_agents.each do |agent|
      Enterprise::AgentCapacityPolicyUser.find_or_create_by!(
        agent_capacity_policy: policy2,
        user: agent
      )
    end
    
    # Set inbox limit
    Enterprise::InboxCapacityLimit.find_or_create_by!(
      agent_capacity_policy: policy2,
      inbox: inbox
    ) do |limit|
      limit.conversation_limit = 10
    end
    
    policies << policy2
    puts "  ✓ Capacity Policy: #{policy2.name} (#{mid_agents.count} agents, limit: 10)"
    
    # Capacity Policy 3: Senior Agent Capacity
    policy3 = Enterprise::AgentCapacityPolicy.find_or_create_by!(
      account: account,
      name: "Senior Agent Capacity"
    ) do |p|
      p.description = "Higher capacity for experienced agents (20 conversations max)"
      p.exclusion_rules = {
        labels: ["executive"],
        hours_threshold: 24
      }
    end
    
    # Assign senior agents
    senior_agents.each do |agent|
      Enterprise::AgentCapacityPolicyUser.find_or_create_by!(
        agent_capacity_policy: policy3,
        user: agent
      )
    end
    
    # Set inbox limit
    Enterprise::InboxCapacityLimit.find_or_create_by!(
      agent_capacity_policy: policy3,
      inbox: inbox
    ) do |limit|
      limit.conversation_limit = 20
    end
    
    policies << policy3
    puts "  ✓ Capacity Policy: #{policy3.name} (#{senior_agents.count} agents, limit: 20)"
    
    # Capacity Policy 4: Specialist Capacity
    policy4 = Enterprise::AgentCapacityPolicy.find_or_create_by!(
      account: account,
      name: "Technical Specialist Capacity"
    ) do |p|
      p.description = "Moderate capacity for technical specialists (15 conversations max)"
      p.exclusion_rules = {
        labels: [],
        hours_threshold: 12
      }
    end
    
    # Assign specialist agents
    specialist_agents.each do |agent|
      Enterprise::AgentCapacityPolicyUser.find_or_create_by!(
        agent_capacity_policy: policy4,
        user: agent
      )
    end
    
    # Set inbox limit
    Enterprise::InboxCapacityLimit.find_or_create_by!(
      agent_capacity_policy: policy4,
      inbox: inbox
    ) do |limit|
      limit.conversation_limit = 15
    end
    
    policies << policy4
    puts "  ✓ Capacity Policy: #{policy4.name} (#{specialist_agents.count} agents, limit: 15)"
    
    # Capacity Policy 5: Team Lead Capacity
    policy5 = Enterprise::AgentCapacityPolicy.find_or_create_by!(
      account: account,
      name: "Team Lead Capacity"
    ) do |p|
      p.description = "Limited capacity for team leads who also manage (5 conversations max)"
      p.exclusion_rules = {
        labels: [],
        hours_threshold: 6
      }
    end
    
    # Assign lead agents
    lead_agents.each do |agent|
      Enterprise::AgentCapacityPolicyUser.find_or_create_by!(
        agent_capacity_policy: policy5,
        user: agent
      )
    end
    
    # Set inbox limit
    Enterprise::InboxCapacityLimit.find_or_create_by!(
      agent_capacity_policy: policy5,
      inbox: inbox
    ) do |limit|
      limit.conversation_limit = 5
    end
    
    policies << policy5
    puts "  ✓ Capacity Policy: #{policy5.name} (#{lead_agents.count} agents, limit: 5)"
    
    # Capacity Policy 6: Weekend Coverage
    policy6 = Enterprise::AgentCapacityPolicy.find_or_create_by!(
      account: account,
      name: "Weekend Coverage Capacity"
    ) do |p|
      p.description = "Increased capacity for weekend skeleton crew (25 conversations max)"
      p.exclusion_rules = {
        labels: ["scheduled", "non-urgent"],
        hours_threshold: 96
      }
    end
    
    # This policy can be applied to any agents working weekends
    # Not assigning anyone by default
    
    # Set inbox limit
    Enterprise::InboxCapacityLimit.find_or_create_by!(
      agent_capacity_policy: policy6,
      inbox: inbox
    ) do |limit|
      limit.conversation_limit = 25
    end
    
    policies << policy6
    puts "  ✓ Capacity Policy: #{policy6.name} (0 agents, limit: 25) - for weekend use"
    
    policies
  rescue => e
    puts "  ⚠️  Could not create capacity policies: #{e.message}"
    []
  end

  def create_scenario_based_conversations(account, inbox)
    conversations = []
    
    # Comprehensive message templates
    scenarios = {
      urgent_technical: {
        messages: [
          "URGENT: Production API is returning 500 errors!",
          "Critical: Database connection pool exhausted",
          "Emergency: Customer data export failing",
          "URGENT: Payment webhook not processing"
        ],
        labels: ["urgent", "technical", "high-priority"],
        count: 5
      },
      vip_sales: {
        messages: [
          "Enterprise evaluation - 1000+ agent requirement",
          "Fortune 500 inquiry about custom features",
          "Government contract compliance questions",
          "Multi-national deployment requirements"
        ],
        labels: ["vip", "sales", "enterprise"],
        count: 5
      },
      billing_issues: {
        messages: [
          "Duplicate charge on my credit card",
          "Invoice showing incorrect amount",
          "Need to update payment method urgently",
          "Refund request for accidental purchase"
        ],
        labels: ["billing", "financial"],
        count: 10
      },
      technical_support: {
        messages: [
          "API rate limiting questions",
          "Webhook configuration help needed",
          "Integration with Salesforce not working",
          "Custom reporting requirements"
        ],
        labels: ["technical", "integration"],
        count: 15
      },
      general_inquiries: {
        messages: [
          "How to add team members?",
          "What's the difference between plans?",
          "Can I schedule messages?",
          "How to export conversation history?"
        ],
        labels: ["general", "question"],
        count: 20
      },
      feature_requests: {
        messages: [
          "Can you add dark mode?",
          "Need bulk operations feature",
          "Request for mobile app improvements",
          "Custom fields for contacts"
        ],
        labels: ["feature-request", "enhancement"],
        count: 10
      },
      training_suitable: {
        messages: [
          "How do I reset my password?",
          "Where can I find my API key?",
          "How to change notification settings?",
          "What is the file size limit?"
        ],
        labels: ["training", "simple"],
        count: 15
      },
      complex_issues: {
        messages: [
          "Complex integration scenario with multiple systems",
          "Performance issues with large data sets",
          "Custom authentication implementation",
          "Advanced automation workflow setup"
        ],
        labels: ["complex", "specialist-required"],
        count: 10
      },
      escalated_complaints: {
        messages: [
          "Very unhappy with support response time",
          "Third time reporting the same issue",
          "Threatening to cancel subscription",
          "Need to speak with management"
        ],
        labels: ["escalated", "complaint", "retention-risk"],
        count: 5
      },
      scheduled_followups: {
        messages: [
          "Following up on our call last week",
          "Checking status of feature request",
          "Monthly account review",
          "Quarterly business review prep"
        ],
        labels: ["scheduled", "follow-up"],
        count: 10
      }
    }
    
    # Create conversations for each scenario
    scenarios.each do |scenario_key, scenario_data|
      scenario_data[:count].times do |i|
        begin
          # Create contact
          contact = account.contacts.create!(
            name: "#{scenario_key.to_s.humanize} Customer #{i+1}",
            email: "#{scenario_key}_#{i+1}_#{Time.current.to_i}@test.com",
            phone_number: "+1555#{rand(1000000..9999999)}"
          )
          
          # Create contact inbox
          contact_inbox = inbox.contact_inboxes.create!(
            contact: contact,
            source_id: "test_#{scenario_key}_#{Time.current.to_i}_#{i}"
          )
          
          # Create conversation
          conversation = inbox.conversations.create!(
            account: account,
            contact: contact,
            contact_inbox: contact_inbox,
            assignee: nil, # Start unassigned
            status: 'open',
            additional_attributes: {
              source: 'test_generator',
              scenario: scenario_key.to_s,
              test_batch: Time.current.to_i
            }
          )
          
          # Add labels
          conversation.update(label_list: scenario_data[:labels])
          
          # Create initial message
          conversation.messages.create!(
            content: scenario_data[:messages].sample,
            account: account,
            inbox: inbox,
            message_type: :incoming,
            sender: contact
          )
          
          # Add follow-up messages for some scenarios
          if [:urgent_technical, :escalated_complaints, :vip_sales].include?(scenario_key) && [true, false].sample
            conversation.messages.create!(
              content: "This is really urgent, please respond ASAP!",
              account: account,
              inbox: inbox,
              message_type: :incoming,
              sender: contact
            )
          end
          
          # Vary creation time based on scenario
          time_ago = case scenario_key
          when :urgent_technical, :escalated_complaints
            rand(1..6).hours.ago
          when :vip_sales
            rand(2..12).hours.ago
          when :scheduled_followups
            rand(1..7).days.ago
          else
            rand(6..72).hours.ago
          end
          
          conversation.update_columns(
            created_at: time_ago,
            updated_at: time_ago
          )
          
          conversations << conversation
          print "."
          
        rescue => e
          print "✗"
          puts "\nError creating #{scenario_key} conversation #{i+1}: #{e.message}"
        end
      end
    end
    
    puts "\n"
    conversations
  end

  def assign_test_conversations(conversations, agents)
    # Simulate Assignment V2 behavior with policy limits
    assigned_count = 0
    inbox = conversations.first.inbox
    
    # Get the active assignment policy for the inbox
    assignment_policy = inbox.assignment_policy
    
    if assignment_policy && assignment_policy.enabled?
      puts "\n  ✓ Found active policy: #{assignment_policy.name}"
      puts "    - Fair Distribution Limit: #{assignment_policy.fair_distribution_limit}"
      puts "    - Fair Distribution Window: #{assignment_policy.fair_distribution_window} seconds"
      puts "\n  🔄 Simulating policy-based assignment..."
      
      # Track assignments per agent within the time window
      agent_assignment_counts = {}
      window_start = assignment_policy.fair_distribution_window.seconds.ago
      
      # Count existing assignments within the time window
      agents.each do |agent|
        recent_count = Conversation.where(
          assignee: agent,
          inbox: inbox,
          updated_at: window_start..Time.current
        ).count
        agent_assignment_counts[agent.id] = recent_count
        puts "    - #{agent.name}: #{recent_count} existing assignments in window"
      end
      
      # Assign conversations respecting the policy limits
      unassigned_conversations = conversations.select { |c| c.assignee.nil? }
      round_robin_index = 0
      
      unassigned_conversations.each do |conversation|
        assigned = false
        attempts = 0
        
        # Try to find an agent who hasn't reached their limit
        while !assigned && attempts < agents.count
          agent = agents[round_robin_index % agents.count]
          current_count = agent_assignment_counts[agent.id] || 0
          
          if current_count < assignment_policy.fair_distribution_limit
            conversation.update!(assignee: agent)
            agent_assignment_counts[agent.id] = current_count + 1
            assigned = true
            assigned_count += 1
            print "."
          end
          
          round_robin_index += 1
          attempts += 1
        end
        
        if !assigned
          print "X" # No agent available within limits
        end
      end
      
      puts "\n  ✓ Policy-based assignment complete: #{assigned_count} conversations assigned"
    else
      puts "\n  ⚠️  No active assignment policy found. Using simple round-robin..."
      
      # Simple round-robin assignment
      unassigned_conversations = conversations.select { |c| c.assignee.nil? }
      unassigned_conversations.each_with_index do |conv, i|
        agent = agents[i % agents.count]
        conv.update!(assignee: agent)
        assigned_count += 1
        print "."
      end
      
      puts "\n  ✓ Assigned #{assigned_count} conversations"
    end
    
    # Show assignment distribution
    puts "\n  📊 Assignment Distribution:"
    agent_assignments = conversations.reload.group_by(&:assignee)
    agents.each do |agent|
      count = agent_assignments[agent]&.count || 0
      level = agent.custom_attributes&.dig('level') || 'unknown'
      puts "     - #{agent.name} (#{level}): #{count} conversations"
    end
  end

  def clear_test_data(account)
    # Clear test conversations
    test_conversations = account.conversations.joins(:messages)
      .where("conversations.additional_attributes->>'source' = ?", 'test_generator')
    count = test_conversations.count
    test_conversations.destroy_all
    puts "  ✓ Deleted #{count} test conversations"
    
    # Clear test contacts with pattern matching
    test_contacts = account.contacts.where(
      "email LIKE '%@test.com' OR email LIKE '%@example.com'"
    )
    count = test_contacts.count
    test_contacts.destroy_all
    puts "  ✓ Deleted #{count} test contacts"
    
    # Clear test agents (optional - uncomment if needed)
    # test_users = account.users.where("custom_attributes->>'test_agent' = ?", 'true')
    # count = test_users.count
    # test_users.destroy_all
    # puts "  ✓ Deleted #{count} test agents"
  end
end