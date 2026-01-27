# frozen_string_literal: true

# Single embedder for all embedding operations (single text or batch)
# Usage:
#   Embedders::DocumentEmbedder.call(text: "single text", tenant: account)
#   Embedders::DocumentEmbedder.call(texts: ["text1", "text2"], tenant: account)
class Embedders::DocumentEmbedder < RubyLLM::Agents::Embedder
  model 'text-embedding-3-small'
  dimensions 1536
  batch_size 100
  cache_for 1.week

  description 'Generates embeddings for knowledge base documents and search queries'
  version '1.0'

  MAX_TEXT_LENGTH = 8000

  def preprocess(text)
    return '' if text.blank?

    text.to_s.truncate(MAX_TEXT_LENGTH, omission: '')
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
