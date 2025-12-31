# frozen_string_literal: true

# Base class for all Aloo AI agents
#
# Example:
#   class MyAgent < ApplicationAgent
#     param :query, required: true
#
#     def user_prompt
#       query
#     end
#   end
#
# Usage:
#   MyAgent.call(query: "hello")
#
class ApplicationAgent < RubyLLM::Agents::Base
  # Default model configuration for all agents
  model 'gemini-2.0-flash'
  temperature 0.7
  version '1.0'
  timeout 60

  # Reliability settings
  retries max: 2, backoff: :exponential

  protected

  # Access personality prompt from current assistant
  def personality_prompt
    return nil unless Aloo::Current.assistant

    Aloo::PersonalityBuilder.new(Aloo::Current.assistant).build
  end

  # Access language instructions from current assistant
  def language_instructions
    assistant = Aloo::Current.assistant
    return nil unless assistant&.language_instruction.present?

    "## Language Instructions\n#{assistant.language_instruction}"
  end

  # Current context helpers for accessing request-scoped data
  def current_account
    Aloo::Current.account
  end

  def current_assistant
    Aloo::Current.assistant
  end

  def current_conversation
    Aloo::Current.conversation
  end

  def current_contact
    Aloo::Current.contact
  end

  def current_inbox
    Aloo::Current.inbox
  end
end
