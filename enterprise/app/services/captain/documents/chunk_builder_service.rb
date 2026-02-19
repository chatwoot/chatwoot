class Captain::Documents::ChunkBuilderService
  def initialize(document)
    @document = document
    @embedding_service = Captain::Documents::ChunkEmbeddingService.new(account_id: document.account_id)
  end

  def process
    raise ArgumentError, 'Document content is required for chunk building' if @document.content.blank?

    chunks = Captain::Documents::ChunkingService.new(@document.content).chunk

    @document.update!(
      chunking_status: :chunking,
      last_chunk_error: nil,
      chunks_generated_at: nil,
      expected_chunk_count: chunks.count,
      indexed_chunk_count: 0
    )

    indexed_count = rebuild_chunks(chunks)

    @document.update!(
      chunking_status: :ready,
      indexed_chunk_count: indexed_count,
      chunks_generated_at: Time.current
    )
  rescue StandardError => e
    @document.update!(chunking_status: :failed, last_chunk_error: e.message)
    raise
  end

  private

  def rebuild_chunks(chunks)
    @document.update!(chunking_status: :indexing)

    @document.chunks.delete_all

    chunks.each_with_index do |chunk, index|
      context = generate_context(chunk[:content])
      attributes = @embedding_service.build_record_attributes(document: @document, chunk: chunk, context: context)
      Captain::DocumentChunk.create!(attributes)
      @document.update_column(:indexed_chunk_count, index + 1) # rubocop:disable Rails/SkipsModelValidations
    end

    chunks.count
  end

  def generate_context(chunk_content)
    Captain::Documents::ContextGenerationService.new(
      document_content: @document.content,
      chunk_content: chunk_content,
      account_id: @document.account_id
    ).generate
  end
end
