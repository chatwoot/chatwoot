class Captain::Documents::ChunkEmbeddingService
  def initialize(account_id:)
    @account_id = account_id
    @embedding_service = Captain::Llm::EmbeddingService.new(account_id: account_id)
  end

  def embed(content:, context: nil)
    input = embedding_input(content: content, context: context)
    return [] if input.blank?

    @embedding_service.get_embedding(input)
  end

  def build_record_attributes(document:, chunk:, context: nil)
    content = chunk.fetch(:content)
    {
      document_id: document.id,
      assistant_id: document.assistant_id,
      account_id: document.account_id,
      position: chunk.fetch(:position),
      content: content,
      token_count: chunk[:token_count],
      context: context,
      embedding: embed(content: content, context: context),
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  private

  def embedding_input(content:, context:)
    [context, content].reject(&:blank?).join("\n\n")
  end
end
