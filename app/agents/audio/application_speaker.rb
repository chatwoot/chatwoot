# frozen_string_literal: true

# Base class for all Aloo TTS agents (ruby_llm-agents Speaker DSL)
#
# Usage:
#   Audio::AlooSpeaker.call(text: "Hello", voice_id: "abc123")
#
class Audio::ApplicationSpeaker < RubyLLM::Agents::Speaker
  output_format :mp3

  protected

  def metadata
    { aloo_assistant_id: current_assistant&.id&.to_s }.compact
  end

  def current_account
    Aloo::Current.account
  end

  def current_assistant
    Aloo::Current.assistant
  end

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
