# frozen_string_literal: true

# Evaluation suite for ConversationAgent with Knowledge Base data.
#
# Tests the agent's ability to retrieve and present factual data from
# embedded documents (Avenues Mall directory) in English and Arabic.
#
# Requires KB documents to be processed before running (see the spec file).
#
# Usage:
#   RUN_EVAL=1 bundle exec rspec spec/evals/conversation_agent_kb_eval_spec.rb
#
class ConversationAgent::KbEval < RubyLLM::Agents::Eval::EvalSuite
  agent ConversationAgent

  eval_model 'gpt-4.1'
  eval_temperature 0.0

  dataset 'spec/evals/datasets/conversation_agent_kb.yml'
end
