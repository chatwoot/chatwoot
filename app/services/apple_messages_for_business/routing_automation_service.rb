class AppleMessagesForBusiness::RoutingAutomationService
  def initialize(account)
    @account = account
  end

  # Create predefined routing rules for common Apple Messages use cases
  def create_default_routing_rules
    create_support_routing_rule
    create_sales_routing_rule
    create_billing_routing_rule
    create_intent_based_routing_rules
  end

  private

  def create_support_routing_rule
    # Route conversations with group="support" to Support team
    support_team = @account.teams.find_by(name: 'Support')
    return unless support_team

    AutomationRule.create!(
      account: @account,
      name: 'Apple Messages Support Routing',
      description: 'Route Apple Messages conversations with group="support" to Support team',
      event_name: 'conversation_created',
      conditions: [
        {
          attribute_key: 'apple_messages_group',
          filter_operator: 'equal_to',
          values: ['support'],
          query_operator: nil
        }
      ],
      actions: [
        {
          action_name: 'assign_team',
          action_parameters: [support_team.id]
        },
        {
          action_name: 'add_label',
          action_parameters: ['apple-messages-support']
        }
      ]
    )
  end

  def create_sales_routing_rule
    # Route conversations with group="sales" to Sales team
    sales_team = @account.teams.find_by(name: 'Sales')
    return unless sales_team

    AutomationRule.create!(
      account: @account,
      name: 'Apple Messages Sales Routing',
      description: 'Route Apple Messages conversations with group="sales" to Sales team',
      event_name: 'conversation_created',
      conditions: [
        {
          attribute_key: 'apple_messages_group',
          filter_operator: 'equal_to',
          values: ['sales'],
          query_operator: nil
        }
      ],
      actions: [
        {
          action_name: 'assign_team',
          action_parameters: [sales_team.id]
        },
        {
          action_name: 'add_label',
          action_parameters: ['apple-messages-sales']
        },
        {
          action_name: 'change_priority',
          action_parameters: ['high']
        }
      ]
    )
  end

  def create_billing_routing_rule
    # Route conversations with group="billing" to specialized agent
    billing_agent = @account.users.joins(:account_users)
                           .where(account_users: { role: ['administrator', 'agent'] })
                           .where("users.name ILIKE ?", '%billing%')
                           .first

    return unless billing_agent

    AutomationRule.create!(
      account: @account,
      name: 'Apple Messages Billing Routing',
      description: 'Route Apple Messages conversations with group="billing" to billing specialist',
      event_name: 'conversation_created',
      conditions: [
        {
          attribute_key: 'apple_messages_group',
          filter_operator: 'equal_to',
          values: ['billing'],
          query_operator: nil
        }
      ],
      actions: [
        {
          action_name: 'assign_agent',
          action_parameters: [billing_agent.id]
        },
        {
          action_name: 'add_label',
          action_parameters: ['apple-messages-billing']
        }
      ]
    )
  end

  def create_intent_based_routing_rules
    # Create rules based on common intent values
    intent_mappings = {
      'account_question' => { label: 'account-inquiry', priority: 'medium' },
      'product_inquiry' => { label: 'product-question', priority: 'high' },
      'technical_support' => { label: 'tech-support', priority: 'high' },
      'order_status' => { label: 'order-tracking', priority: 'medium' },
      'complaint' => { label: 'complaint', priority: 'urgent' }
    }

    intent_mappings.each do |intent, config|
      AutomationRule.create!(
        account: @account,
        name: "Apple Messages Intent: #{intent.humanize}",
        description: "Route Apple Messages conversations with intent='#{intent}'",
        event_name: 'conversation_created',
        conditions: [
          {
            attribute_key: 'apple_messages_intent',
            filter_operator: 'equal_to',
            values: [intent],
            query_operator: nil
          }
        ],
        actions: [
          {
            action_name: 'add_label',
            action_parameters: [config[:label]]
          },
          {
            action_name: 'change_priority',
            action_parameters: [config[:priority]]
          }
        ]
      )
    end
  end

  # Helper method to create custom routing rule
  def self.create_custom_routing_rule(account, group: nil, intent: nil, team_id: nil, agent_id: nil, labels: [], priority: nil)
    conditions = []
    actions = []

    # Build conditions
    if group.present?
      conditions << {
        attribute_key: 'apple_messages_group',
        filter_operator: 'equal_to',
        values: [group],
        query_operator: conditions.any? ? 'AND' : nil
      }
    end

    if intent.present?
      conditions << {
        attribute_key: 'apple_messages_intent',
        filter_operator: 'equal_to',
        values: [intent],
        query_operator: conditions.any? ? 'AND' : nil
      }
    end

    return if conditions.empty?

    # Build actions
    actions << { action_name: 'assign_team', action_parameters: [team_id] } if team_id
    actions << { action_name: 'assign_agent', action_parameters: [agent_id] } if agent_id
    actions << { action_name: 'change_priority', action_parameters: [priority] } if priority

    labels.each do |label|
      actions << { action_name: 'add_label', action_parameters: [label] }
    end

    rule_name = "Apple Messages Routing: #{[group, intent].compact.join(' + ')}"

    AutomationRule.create!(
      account: account,
      name: rule_name,
      description: "Custom Apple Messages routing rule for #{[group ? "group=#{group}" : nil, intent ? "intent=#{intent}" : nil].compact.join(' and ')}",
      event_name: 'conversation_created',
      conditions: conditions,
      actions: actions
    )
  end
end