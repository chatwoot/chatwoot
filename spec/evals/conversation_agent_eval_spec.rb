# frozen_string_literal: true

require 'rails_helper'
require_relative 'conversation_agent_eval'

# Evaluation tests for ConversationAgent response quality.
#
# These tests hit the real LLM API and are gated behind RUN_EVAL=1.
# They verify that the agent's behavioral contracts hold across changes
# to prompts, tools, and model configurations.
#
# Run:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_eval_spec.rb
#
# Run a single case:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_eval_spec.rb -e "greeting"
#
RSpec.describe 'ConversationAgent eval', :aloo, if: ENV.fetch('RUN_EVAL', nil) do
  let(:account) { create(:account) }
  let(:assistant) { create(:aloo_assistant, :with_all_features, account: account) }
  let(:inbox) { create(:inbox, account: account) }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:contact) { conversation.contact }

  before do
    WebMock.allow_net_connect!

    Aloo::Current.account = account
    Aloo::Current.assistant = assistant
    Aloo::Current.conversation = conversation
    Aloo::Current.contact = contact
    Aloo::Current.inbox = inbox
  end

  after do
    Aloo::Current.reset
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  describe 'overall quality bar' do
    it 'scores above 70% across all cases' do
      run = ConversationAgent::Eval.run!(pass_threshold: 0.5)

      puts "\n#{run.summary}"
      puts "Duration: #{run.duration_ms}ms | Cost: $#{format('%.4f', run.total_cost)}"

      run.failures.each do |result|
        puts "  FAIL: #{result.test_case_name} (score: #{result.score.value}) — #{result.score.reason}"
      end

      run.errors.each do |result|
        puts "  ERROR: #{result.test_case_name} — #{result.error.class}: #{result.error.message}"
      end

      expect(run.score).to be >= 0.7
      expect(run.errors).to be_empty
    end
  end

  describe 'individual cases' do
    it 'greets appropriately on first message' do
      run = ConversationAgent::Eval.run!(only: 'greeting_first_message', pass_threshold: 0.5)
      expect(run.score).to be >= 0.6
    end

    it 'does not re-greet on follow-up messages' do
      # Simulate conversation history so the agent sees prior context
      create(:message, conversation: conversation, message_type: :incoming, content: 'Hi')
      create(:message, conversation: conversation, message_type: :outgoing, content: 'Hello! How can I help you?')

      run = ConversationAgent::Eval.run!(only: 'greeting_followup', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'does not hallucinate answers to factual questions' do
      run = ConversationAgent::Eval.run!(only: 'factual_question_grounding', pass_threshold: 0.5)
      expect(run.score).to be >= 0.6
    end

    it 'stays within support scope for off-topic questions' do
      run = ConversationAgent::Eval.run!(only: 'unknown_topic_honesty', pass_threshold: 0.5)
      expect(run.score).to be >= 0.6
    end

    it 'keeps responses concise' do
      run = ConversationAgent::Eval.run!(only: 'brevity_simple_question', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'escalates when customer requests a human' do
      run = ConversationAgent::Eval.run!(only: 'explicit_human_request', pass_threshold: 0.5)
      expect(run.score).to be >= 0.6
    end

    it 'shows empathy with frustrated customers' do
      run = ConversationAgent::Eval.run!(only: 'frustrated_customer_escalation', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'respects policy boundaries' do
      run = ConversationAgent::Eval.run!(only: 'policy_override_attempt', pass_threshold: 0.5)
      expect(run.score).to be >= 0.6
    end

    it 'asks for clarification on ambiguous requests' do
      run = ConversationAgent::Eval.run!(only: 'ambiguous_request', pass_threshold: 0.5)
      expect(run.score).to be >= 0.5
    end

    it 'responds concisely to simple thank-you messages' do
      run = ConversationAgent::Eval.run!(only: 'response_not_too_long', pass_threshold: 0.5)
      expect(run.score).to be >= 0.8
    end
  end
end
