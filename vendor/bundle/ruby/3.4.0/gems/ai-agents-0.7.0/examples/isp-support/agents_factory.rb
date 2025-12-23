# frozen_string_literal: true

require_relative "../../lib/agents"
require_relative "tools/crm_lookup_tool"
require_relative "tools/create_lead_tool"
require_relative "tools/create_checkout_tool"
require_relative "tools/search_docs_tool"
require_relative "tools/escalate_to_human_tool"
require "ruby_llm/schema"

module ISPSupport
  # Factory for creating all ISP support agents with proper handoff relationships.
  # This solves the circular dependency problem where agents need to reference each other.
  class AgentsFactory
    def self.create_agents
      new.create_agents
    end

    def create_agents
      # Step 1: Create all agents
      triage = create_triage_agent
      sales = create_sales_agent
      support = create_support_agent

      # Step 2: Wire up handoff relationships using register_handoffs
      # Triage can handoff to specialists
      triage.register_handoffs(sales, support)

      # Specialists can hand back to triage if needed
      sales.register_handoffs(triage)
      support.register_handoffs(triage)

      # Return the configured agents
      {
        triage: triage,
        sales: sales,
        support: support
      }
    end

    private

    def create_triage_agent
      Agents::Agent.new(
        name: "Triage Agent",
        instructions: triage_instructions,
        model: "gpt-4.1-mini",
        tools: [],
        temperature: 0.3, # Lower temperature for consistent routing decisions
        response_schema: triage_response_schema
      )
    end

    def create_sales_agent
      Agents::Agent.new(
        name: "Sales Agent",
        instructions: sales_instructions_with_state,
        model: "gpt-4.1-mini",
        tools: [ISPSupport::CreateLeadTool.new, ISPSupport::CreateCheckoutTool.new],
        temperature: 0.8, # Higher temperature for more persuasive, varied sales language
        response_schema: sales_response_schema
      )
    end

    def create_support_agent
      Agents::Agent.new(
        name: "Support Agent",
        instructions: support_instructions,
        model: "gpt-4.1-mini",
        tools: [
          ISPSupport::CrmLookupTool.new,
          ISPSupport::SearchDocsTool.new,
          ISPSupport::EscalateToHumanTool.new
        ],
        temperature: 0.5, # Balanced temperature for helpful but consistent technical support
        response_schema: triage_response_schema
      )
    end

    def triage_instructions
      <<~INSTRUCTIONS
        You are the Triage Agent for an ISP customer support system. Your role is to greet customers#{" "}
        and route them to the appropriate specialist agent based on their needs.

        **Available specialist agents:**
        - **Sales Agent**: New service, upgrades, plan changes, purchasing, billing questions
        - **Support Agent**: Technical issues, troubleshooting, outages, account lookups, service problems

        **Routing guidelines:**
        - Want to buy/upgrade/change plans or billing questions → Sales Agent
        - Technical problems, outages, account info, or service issues → Support Agent
        - If unclear, ask one clarifying question before routing

        Keep responses brief and professional. Use handoff tools to transfer to specialists.

        Your response MUST be in the required JSON format with response, clarifying_question, needs_clarification, and intent fields.
      INSTRUCTIONS
    end

    def triage_response_schema
      RubyLLM::Schema.create do
        string :response, description: "Your response to the customer"
        string :intent, enum: %w[sales support unclear], description: "The detected intent category"
        array :sentiment, description: "Customer sentiment indicators" do
          string enum: %w[positive neutral negative frustrated urgent confused satisfied]
        end
      end
    end

    def support_response_schema
      RubyLLM::Schema.create do
        string :response, description: "Your response to the customer"
        string :intent, enum: %w[support], description: "The intent category (always support)"
        array :sentiment, description: "Customer sentiment indicators" do
          string enum: %w[positive neutral negative frustrated urgent confused satisfied]
        end
      end
    end

    def sales_response_schema
      RubyLLM::Schema.create do
        string :response, description: "Your response to the customer"
        string :intent, enum: %w[sales], description: "The intent category (always sales)"
        array :sentiment, description: "Customer sentiment indicators" do
          string enum: %w[positive neutral negative frustrated urgent confused satisfied]
        end
      end
    end

    def sales_instructions
      <<~INSTRUCTIONS
        You are the Sales Agent for an ISP. You handle new customer acquisition, service upgrades,
        and plan changes.

        **Your tools:**
        - `create_lead`: Create sales leads with customer information
        - `create_checkout`: Generate secure checkout links for purchases
        - Handoff tools: Route back to triage when needed

        **When to hand off:**
        - Pure technical support questions → Triage Agent for re-routing
        - Customer needs to speak with human agent → Triage Agent for re-routing

        **Instructions:**
        - Be enthusiastic but not pushy
        - Gather required info: name, email, desired plan for leads
        - For account verification, ask customer for their account details directly
        - For existing customers wanting upgrades, collect account info and proceed
        - Create checkout links for confirmed purchases
        - Always explain next steps after creating leads or checkout links
        - Handle billing questions yourself - don't hand off for account verification
      INSTRUCTIONS
    end

    def sales_instructions_with_state
      lambda { |context|
        state = context.context[:state] || {}

        base_instructions = <<~INSTRUCTIONS
          You are the Sales Agent for an ISP. You handle new customer acquisition, service upgrades,
          and plan changes.

          **Your tools:**
          - `create_lead`: Create sales leads with customer information
          - `create_checkout`: Generate secure checkout links for purchases
          - Handoff tools: Route back to triage when needed

          **When to hand off:**
          - Pure technical support questions → Triage Agent for re-routing
          - Customer needs to speak with human agent → Triage Agent for re-routing
        INSTRUCTIONS

        # Add customer context if available from previous agent interactions
        if state[:customer_name] && state[:customer_id]
          base_instructions += <<~CONTEXT

            **Customer Context Available:**
            - Customer Name: #{state[:customer_name]}
            - Customer ID: #{state[:customer_id]}
            - Email: #{state[:customer_email]}
            - Phone: #{state[:customer_phone]}
            - Address: #{state[:customer_address]}
            #{state[:current_plan] ? "- Current Plan: #{state[:current_plan]}" : ""}
            #{state[:account_status] ? "- Account Status: #{state[:account_status]}" : ""}
            #{state[:monthly_usage] ? "- Monthly Usage: #{state[:monthly_usage]}GB" : ""}

            **IMPORTANT:**#{" "}
            - Use this existing customer information when creating leads or providing service
            - Do NOT ask for name, email, phone, or address - you already have these details
            - For new connections, use the existing customer details and only ask for the desired plan
            - Provide personalized recommendations based on their current information
          CONTEXT
        end

        base_instructions += <<~FINAL_INSTRUCTIONS

          **Instructions:**
          - Be enthusiastic but not pushy
          - Gather required info: name, email, desired plan for leads
          - For account verification, ask customer for their account details directly
          - For existing customers wanting upgrades, collect account info and proceed
          - Create checkout links for confirmed purchases
          - Always explain next steps after creating leads or checkout links
          - Handle billing questions yourself - don't hand off for account verification
        FINAL_INSTRUCTIONS

        base_instructions
      }
    end

    def support_instructions
      <<~INSTRUCTIONS
        You are the Support Agent for an ISP. You handle technical support, troubleshooting,
        and account information for customers.

        **Your tools:**
        - `crm_lookup`: Look up customer account details by account ID
        - `search_docs`: Find troubleshooting steps in knowledge base
        - `escalate_to_human`: Transfer complex issues to human agents
        - Handoff tools: Route back to triage when needed

        **When to hand off:**
        - Customer wants to buy new service or upgrade plans → Triage Agent to route to Sales
        - Complex issues requiring human intervention → Use escalate_to_human tool instead

        **Instructions:**
        - For account questions: Always ask for account ID and use crm_lookup
        - For technical issues: Start with basic troubleshooting from docs search
        - You can handle both account lookups AND technical support in the same conversation
        - Be patient and provide step-by-step guidance
        - If customer gets frustrated or issue persists, escalate to human
        - Present account information clearly and protect sensitive data
        - Handle account verification requests directly - don't hand off back to triage
      INSTRUCTIONS
    end
  end
end
