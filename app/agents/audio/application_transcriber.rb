# frozen_string_literal: true

# Base class for all Aloo transcription agents (ruby_llm-agents Transcriber DSL)
#
# Usage:
#   Audio::AlooTranscriber.call(audio: "/path/to/file.mp3", language: "en")
#
class Audio::ApplicationTranscriber < RubyLLM::Agents::Transcriber
  output_format :text

  protected

  def metadata
    {
      account_id: current_account&.id&.to_s,
      assistant_id: current_assistant&.id&.to_s,
      conversation_id: Aloo::Current.conversation&.id&.to_s,
      contact_id: Aloo::Current.contact&.id&.to_s,
      inbox_id: Aloo::Current.inbox&.id&.to_s
    }.compact
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
