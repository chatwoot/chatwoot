# frozen_string_literal: true

# Single embedder for all embedding operations (single text or batch)
# Preprocessing (sanitization, truncation) is handled by Aloo::Embedding
# Usage:
#   Embedders::DocumentEmbedder.call(text: "single text", tenant: account)
#   Embedders::DocumentEmbedder.call(texts: ["text1", "text2"], tenant: account)
class Embedders::DocumentEmbedder < RubyLLM::Agents::Embedder
  description 'Generates embeddings for knowledge base documents and search queries'

  model 'gemini-embedding-001'
  dimensions 3072
  batch_size 100
  cache_for 1.week

  on_failure do
    retries times: 3, backoff: :exponential
    timeout 30.seconds
  end

  def metadata
    {
      account_id: (Current.account&.id || @options.dig(:tenant, :id))&.to_s,
      assistant_id: Aloo::Current.assistant&.id&.to_s
    }.compact
  end

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
