# frozen_string_literal: true

# Generates FAQ entries from conversation transcripts
#
# Example:
#   result = FaqGeneratorAgent.call(transcript: "Customer: ... Agent: ...")
#   result.content  # => [{ question: "...", answer: "...", topics: [...], confidence: 0.8 }]
#
class FaqGeneratorAgent < ApplicationAgent
  temperature 0.5
  version '1.0'

  param :transcript, required: true
  param :max_faqs, default: 3

  def system_prompt
    <<~PROMPT
      You are a FAQ generator. Your job is to analyze resolved customer support conversations
      and create FAQ entries that can help answer similar questions in the future.

      ## Guidelines
      - Only create FAQs for questions that are likely to be asked by other customers
      - Focus on questions that were successfully answered
      - Write clear, concise questions that match how customers naturally ask
      - Write complete, accurate answers based on how the issue was resolved
      - Avoid customer-specific details in FAQs (make them generalizable)
      - Each FAQ should be self-contained and useful on its own
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Analyze this resolved customer support conversation and generate FAQ entries.

      ## Conversation
      #{transcript}

      ## Instructions
      - Generate up to #{max_faqs} FAQs from questions that were successfully answered
      - Skip questions that are too specific to this customer
      - Focus on questions other customers might also ask

      If no suitable FAQs can be generated, return an empty array.
    PROMPT
  end

  def schema
    RubyLLM::Schema.create do
      array :faqs, of: :object do
        string :question, description: 'The question as a customer would ask it'
        string :answer, description: 'Clear, helpful answer'
        array :topics, of: :string, description: 'Relevant topics for categorization'
        number :confidence, description: '0.0-1.0 rating of how generally applicable this FAQ is'
      end
    end
  end
end
