# frozen_string_literal: true

# Evaluation suite for ConversationAgent response quality.
#
# Tests the agent's behavioral contracts:
#   - Greeting style (first message vs. follow-up)
#   - Knowledge grounding (no hallucination)
#   - Brevity and conciseness
#   - Human handoff escalation
#   - Policy boundary enforcement
#   - Clarification behavior
#
# Usage:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_eval_spec.rb
#
class ConversationAgent::Eval < RubyLLM::Agents::Eval::EvalSuite
  agent ConversationAgent

  eval_model 'gpt-4.1'
  eval_temperature 0.0

  dataset 'spec/evals/datasets/conversation_agent.yml'

  # Additional programmatic test case: response length check
  test_case 'response_not_too_long',
            input: lambda {
              { message: 'Thanks for your help!' }
            },
            score: lambda { |result, _expected|
              content = result.respond_to?(:content) ? result.content.to_s : result.to_s
              # Support agent responses should be concise — under 500 chars for a simple thank-you
              content.length <= 500 ? 1.0 : 0.0
            }
end
