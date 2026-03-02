# frozen_string_literal: true

# Base class for all Aloo AI agents (ruby_llm-agents v3 DSL)
#
# Example (static prompts — class-level template DSL):
#   class MyAgent < ApplicationAgent
#     param :query, required: true
#
#     system "You are a helpful assistant."
#     user "Answer this: {query}"
#
#     returns do
#       string :answer, description: 'The answer'
#     end
#   end
#
# Example (dynamic prompts — instance method overrides):
#   class MyAgent < ApplicationAgent
#     def system_prompt
#       [base_instructions, context_section].compact.join("\n\n")
#     end
#
#     def user_prompt
#       build_dynamic_prompt
#     end
#   end
#
# Usage:
#   MyAgent.call(query: "hello")
#   MyAgent.ask("freeform question")
#
class ApplicationAgent < RubyLLM::Agents::Base
  # Default model configuration for all agents
  model 'gpt-4o-mini'
  temperature 0.7
  timeout 60

  on_failure do
    retries times: 2, backoff: :exponential
  end

  private

  # Override to include tracked tool calls in the Result.
  # BaseAgent#build_result omits tool_calls/tool_calls_count,
  # so result.tool_calls always defaults to [].
  def build_result(content, response, context)
    result = super
    return result if @tracked_tool_calls.empty?

    RubyLLM::Agents::Result.new(
      **result.to_h,
      tool_calls: @tracked_tool_calls,
      tool_calls_count: @tracked_tool_calls.size
    )
  end

  protected

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
    tenant = @options[:tenant] || Aloo::Current.account
    return nil unless tenant

    if tenant.respond_to?(:llm_tenant_id)
      { id: tenant.llm_tenant_id, object: tenant }
    elsif tenant.is_a?(Hash)
      tenant
    end
  end
end
