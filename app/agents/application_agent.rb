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
  model 'gpt-4o-mini'
  temperature 0.7
  version '1.0'
  timeout 60

  # Reliability settings
  reliability do
    retries max: 2, backoff: :exponential
  end

  protected

  # Access personality prompt from current assistant
  def personality_prompt
    return nil unless Aloo::Current.assistant

    Aloo::PersonalityBuilder.new(Aloo::Current.assistant).build
  end

  # Access language instructions from current assistant
  def language_instructions
    assistant = Aloo::Current.assistant
    return nil if assistant&.language_instruction.blank?

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

  # Override resolve_tenant to automatically use Current.account when no explicit tenant is passed
  def resolve_tenant
    tenant = @options[:tenant] || Current.account
    return nil unless tenant

    if tenant.respond_to?(:llm_tenant_id)
      { id: tenant.llm_tenant_id, object: tenant }
    elsif tenant.is_a?(Hash)
      tenant
    end
  end
end
