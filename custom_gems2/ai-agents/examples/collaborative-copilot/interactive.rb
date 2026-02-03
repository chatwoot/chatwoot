#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require_relative "../../lib/agents"
require_relative "agents/copilot_orchestrator"

# Configure the agents SDK
Agents.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.default_model = "gpt-4o-mini"
  config.debug = false
end

puts "=== Support Copilot Demo ==="
puts "This demonstrates agent-as-tool collaboration where specialist agents work behind the scenes."
puts

# Create the main copilot
copilot = Copilot::CopilotOrchestrator.create
runner = Agents::Runner.with_agents(copilot)
context = {}

# Demo scenarios
# scenarios = [
#   {
#     title: "API Errors - Enterprise Customer",
#     query: "mike.chen@techfirm.com reporting API 500 errors (CONV-004). Help?"
#   },
#   {
#     title: "Angry Customer - Login + Billing",
#     query: "john.smith@example.com can't login AND has billing issues (CONV-001). Threatening to cancel. What do I do?"
#   },
#   {
#     title: "Dark Mode Feature Request",
#     query: "Customer asking about dark mode. Is this being worked on? Should I create a ticket?"
#   },
#   {
#     title: "Enterprise Integration Issues",
#     query: "CONTACT-789 can't get API integration working. Need help with response."
#   }
# ]

# scenarios.each_with_index do |scenario, i|
#   puts("-" * 60)
#   puts "Scenario #{i + 1}: #{scenario[:title]}"
#   puts("-" * 60)
#   puts "Support Agent Query: #{scenario[:query]}"
#   puts
#   puts "Copilot Response:"
#   puts

#   begin
#     result = runner.run(scenario[:query])
#     puts result.output
#   rescue StandardError => e
#     puts "Error: #{e.message}"
#   end

#   puts
#   puts "Press Enter to continue to next scenario..."
#   gets
#   puts
# end

puts "=== Interactive Mode ==="
puts "Now you can ask the copilot questions directly."
puts "Type 'exit' to quit."
puts

loop do
  print "Support Agent: "
  input = gets.chomp
  break if input.downcase == "exit"

  puts
  puts "Copilot:"
  begin
    result = runner.run(input, context: context)

    # Update context with the returned context from Runner
    context = result.context if result.respond_to?(:context) && result.context

    output = result.output

    # Check if the output might be structured JSON (e.g., from Analysis Agent)
    if output&.strip&.start_with?("{") && context[:current_agent] == "Analysis Agent"
      begin
        analysis = JSON.parse(output)

        # Display structured analysis in a readable format
        puts "\n📊 Conversation Analysis:"
        puts "━" * 60

        # Conversation Health
        health = analysis["conversation_health"]
        puts "🏥 Health: #{health["status"].upcase} - #{health["summary"]}"

        # Customer Sentiment
        sentiment = analysis["customer_sentiment"]
        puts "😊 Sentiment: #{sentiment["current"]} (#{sentiment["trajectory"]})"
        puts "   Emotions: #{sentiment["key_emotions"].join(", ")}"

        # Communication Quality
        quality = analysis["communication_quality"]
        puts "💬 Communication: #{quality["score"]}/10"
        puts "   ✅ Strengths: #{quality["strengths"].join(", ")}" if quality["strengths"].any?
        puts "   ⚠️  Improve: #{quality["areas_for_improvement"].join(", ")}" if quality["areas_for_improvement"].any?

        # Risk Assessment
        risk = analysis["risk_assessment"]
        puts "⚠️  Risks: Escalation=#{risk["escalation_risk"]}, Churn=#{risk["churn_risk"]}"
        puts "   Warning signs: #{risk["warning_signs"].join(", ")}" if risk["warning_signs"].any?

        # Tone Recommendations
        tone = analysis["tone_recommendations"]
        puts "\n💡 Recommendations:"
        puts "   Tone: #{tone["recommended_tone"]}"
        puts "   Next: #{tone["next_steps"]}"
        puts "   Use: #{tone["key_phrases"].join("; ")}" if tone["key_phrases"].any?
        puts "   Avoid: #{tone["avoid_phrases"].join("; ")}" if tone["avoid_phrases"].any?

        puts "━" * 60
      rescue JSON::ParserError
        # Fall back to regular output if not valid JSON
        puts output
      end
    else
      puts output
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
  puts
end

puts "Thanks for trying the Support Copilot demo!"
