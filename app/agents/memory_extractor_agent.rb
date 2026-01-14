# frozen_string_literal: true

# Extracts learnings and memories from conversation transcripts
#
# Example:
#   result = MemoryExtractorAgent.call(
#     transcript: "Customer: ... Agent: ...",
#     resolution_status: "resolved"
#   )
#   result.content  # => { memories: [...] }
#
class MemoryExtractorAgent < ApplicationAgent
  description 'Extracts learnings and memories from conversation transcripts'
  model 'gemini-2.5-flash'
  temperature 0.5
  version '1.0'

  fallback_models 'gpt-4.1-mini', 'claude-haiku-4-5'

  param :transcript, required: true
  param :resolution_status
  param :max_memories, default: 10

  # Memory types we can extract
  MEMORY_TYPES = {
    'preference' => 'Customer preferences (communication style, product preferences, etc.)',
    'commitment' => 'Promises or commitments made to the customer',
    'decision' => 'Decisions made during the conversation',
    'correction' => 'Corrections to previous misunderstandings or errors',
    'procedure' => 'Procedures or processes learned that apply generally',
    'faq' => 'Frequently asked questions and their answers',
    'insight' => 'General insights about customer needs or patterns',
    'gap' => "Knowledge gaps identified (things we should know but don't)"
  }.freeze

  def system_prompt
    <<~PROMPT
      You are a memory extraction agent. Your job is to analyze customer support conversations
      and extract valuable learnings that can improve future interactions.

      ## Memory Types
      #{format_memory_types}

      ## Guidelines
      - Only extract genuinely useful information, not obvious or trivial details
      - Be specific and actionable in your extractions
      - For customer preferences/commitments, note the specific customer context
      - For procedures/insights, ensure they're generalizable
      - Identify knowledge gaps when the agent couldn't answer something
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Analyze this customer support conversation and extract valuable learnings.

      ## Conversation
      #{transcript}

      ## Resolution Status
      This conversation was #{resolution_status || 'unknown'}. #{resolution_context}

      Extract up to #{max_memories} memories.
    PROMPT
  end

  def schema
    RubyLLM::Schema.create do
      array :memories, of: :object do
        string :type, description: 'Memory type: preference, commitment, decision, correction, procedure, faq, insight, gap'
        string :content, description: 'Clear, concise description of the learning'
        array :entities, of: :string, description: 'Relevant entity names (people, products, features)'
        array :topics, of: :string, description: 'Relevant topics'
        boolean :contact_specific, description: 'True if this applies only to this customer'
      end
    end
  end

  private

  def format_memory_types
    MEMORY_TYPES.map { |type, desc| "- #{type}: #{desc}" }.join("\n")
  end

  def resolution_context
    case resolution_status
    when 'resolved'
      'Focus on successful patterns and learnings.'
    when 'open'
      'Note any unresolved issues or knowledge gaps.'
    else
      ''
    end
  end
end
