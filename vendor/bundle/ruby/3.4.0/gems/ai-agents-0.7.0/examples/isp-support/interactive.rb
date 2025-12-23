#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "readline"
require_relative "../../lib/agents"
require_relative "agents_factory"

# Simple ISP Customer Support Demo
class ISPSupportDemo
  def initialize
    # Configure the Agents SDK with API key
    Agents.configure do |config|
      config.openai_api_key = ENV["OPENAI_API_KEY"]
    end

    # Create agents
    @agents = ISPSupport::AgentsFactory.create_agents

    # Create thread-safe runner with all agents (triage first = default entry point)
    @runner = Agents::Runner.with_agents(
      @agents[:triage],
      @agents[:sales],
      @agents[:support]
    )

    # Setup real-time callbacks for UI feedback
    setup_callbacks

    @context = {}
    @current_status = ""

    puts green("🏢 Welcome to ISP Customer Support!")
    puts dim_text("Type '/help' for commands or 'exit' to quit.")
    puts
  end

  def start
    loop do
      user_input = Readline.readline(cyan("\u{1F4AC} You: "), true)
      next unless user_input # Handle Ctrl+D

      user_input = user_input.strip
      command_result = handle_command(user_input)
      break if command_result == :exit
      next if command_result == :handled || user_input.empty?

      # Clear any previous status and show agent is working
      clear_status_line
      print yellow("🤖 Processing...")

      begin
        # Use the runner - it automatically determines the right agent from context
        result = @runner.run(user_input, context: @context)

        # Update our context with the returned context from Runner
        @context = result.context if result.respond_to?(:context) && result.context

        # Clear status and show response with callback history
        clear_status_line

        # Display callback messages if any
        if @callback_messages.any?
          puts dim_text(@callback_messages.join("\n"))
          @callback_messages.clear
        end

        # Handle structured output from agents
        output = result.output || "[No output]"

        if output.is_a?(Hash) && output.key?("response")
          # Display the response from structured response
          puts "🤖 #{output["response"]}"
          puts dim_text("   [Intent]: #{output["intent"]}") if output["intent"]
          puts dim_text("   [Sentiment]: #{output["sentiment"].join(", ")}") if output["sentiment"]&.any?
        else
          puts "🤖 #{output}"
        end

        puts # Add blank line after agent response
      rescue StandardError => e
        clear_status_line
        puts red("❌ Error: #{e.message}")
        puts dim_text("Please try again or type '/help' for assistance.")
        puts # Add blank line after error message
      end
    end
  end

  private

  def setup_callbacks
    @callback_messages = []

    @runner.on_agent_thinking do |agent_name, _input|
      message = "🧠 #{agent_name} is thinking..."
      update_status(message)
      @callback_messages << message
    end

    @runner.on_tool_start do |tool_name, _args|
      message = "🔧 Using #{tool_name}..."
      update_status(message)
      @callback_messages << message
    end

    @runner.on_tool_complete do |tool_name, _result|
      message = "✅ #{tool_name} completed"
      update_status(message)
      @callback_messages << message
    end

    @runner.on_agent_handoff do |from_agent, to_agent, _reason|
      message = "🔄 Handoff: #{from_agent} → #{to_agent}"
      update_status(message)
      @callback_messages << message
    end
  end

  def update_status(message)
    clear_status_line
    print dim_text(message)
    $stdout.flush
  end

  def clear_status_line
    print "\r#{" " * 80}\r" # Clear the current line
    $stdout.flush
  end

  def handle_command(input)
    case input.downcase
    when "exit", "quit"
      dump_context_and_quit
      puts "👋 Goodbye!"
      :exit
    when "/help"
      show_help
      :handled
    when "/reset"
      @context.clear
      puts "🔄 Context reset. Starting fresh conversation."
      :handled
    when "/agents"
      show_agents
      :handled
    when "/tools"
      show_tools
      :handled
    when "/context"
      show_context
      :handled
    else
      :not_command # Not a command, continue with normal processing
    end
  end

  def dump_context_and_quit
    project_root = File.expand_path("../..", __dir__)
    tmp_directory = File.join(project_root, "tmp")

    # Ensure tmp directory exists
    Dir.mkdir(tmp_directory) unless Dir.exist?(tmp_directory)

    timestamp = Time.now.to_i
    context_filename = File.join(tmp_directory, "context-#{timestamp}.json")

    File.write(context_filename, JSON.pretty_generate(@context))

    puts "💾 Context saved to tmp/context-#{timestamp}.json"
  end

  def show_help
    puts "📋 Available Commands:"
    puts "  /help     - Show this help message"
    puts "  /reset    - Clear conversation context and start fresh"
    puts "  /agents   - List all available agents"
    puts "  /tools    - Show tools available to agents"
    puts "  /context  - Show current conversation context"
    puts "  exit/quit - End the session"
    puts
    puts "💡 Example customer requests:"
    puts "  - 'What's my current plan?' (try account ID: CUST001)"
    puts "  - 'I want to upgrade my internet'"
    puts "  - 'My internet is slow'"
  end

  def show_agents
    puts "🤖 Available Agents:"
    @agents.each do |key, agent|
      puts "  #{agent.name} - #{get_agent_description(key)}"
    end
  end

  def show_tools
    puts "🔧 Agent Tools:"
    @agents.each_value do |agent|
      puts "  #{agent.name}:"
      if agent.all_tools.empty?
        puts "    (no tools)"
      else
        agent.all_tools.each do |tool|
          puts "    - #{tool.name}: #{tool.description}"
        end
      end
    end
  end

  def show_context
    puts "📊 Current Context:"
    if @context.empty?
      puts "  (empty)"
    else
      @context.each do |key, value|
        puts "  #{key}: #{value}"
      end
    end
  end

  def get_agent_description(key)
    case key
    when :triage then "Routes customers to appropriate specialists"
    when :customer_info then "Handles account information and billing"
    when :sales then "Manages new sales and upgrades"
    when :support then "Provides technical support and troubleshooting"
    else "Unknown agent"
    end
  end

  # ANSI color helper methods
  def dim_text(text)
    "\e[90m#{text}\e[0m"
  end

  def green(text)
    "\e[32m#{text}\e[0m"
  end

  def yellow(text)
    "\e[33m#{text}\e[0m"
  end

  def red(text)
    "\e[31m#{text}\e[0m"
  end

  def cyan(text)
    "\e[36m#{text}\e[0m"
  end
end

# Run the demo
ISPSupportDemo.new.start if __FILE__ == $PROGRAM_NAME
