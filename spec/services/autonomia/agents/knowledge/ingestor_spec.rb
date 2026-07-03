require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Ingestor do
  let(:account) { create(:account) }
  let(:agent) do
    Autonomia::Agents::Agent.create!(account: account, name: 'Agente Teste', agent_type: 'support')
  end
  let(:source) do
    Autonomia::Agents::Source.create!(account: account, agent: agent, source_type: 'pdf', status: :pending)
  end
  let(:processor) { instance_double(Autonomia::Agents::Knowledge::Processors::Pdf) }
  let(:embedder) { instance_double(Autonomia::Agents::EmbeddingService) }
  let(:classifier) { instance_double(Autonomia::Agents::Knowledge::DocumentClassifier) }

  # Documento de prosa com um cabeçalho gritado + corpo — gera >= 1 chunk com heading herdado.
  let(:text) do
    "POLITICA DE REEMBOLSO\n\nO reembolso integral e processado em ate trinta dias uteis para o cliente."
  end
  let(:doc_classification) do
    { topics: ['Reembolso'], entities: ['Plano Plus'], doc_style: 'formal' }
  end
  # Vetor fake com a dimensão da coluna ativa (1536) — extraído p/ constante local (Performance).
  let(:fake_vector) { Array.new(1536, 0.1) }

  def run!
    token = source.begin_ingestion!
    described_class.new(source: source, token: token).perform
  end

  before do
    # Processors.for delega a Processors::Dispatcher.for (método de classe verificável); stubamos o
    # dispatcher p/ não tocar o extrator real de PDF.
    allow(Autonomia::Agents::Knowledge::Processors::Dispatcher).to receive(:for).with(source).and_return(processor)
    allow(processor).to receive(:extract).and_return(text)
    # 1 vetor por chunk (qualquer chunk count); vetor não-vazio p/ passar do guard de embeddings.
    allow(embedder).to receive(:embed_batch) { |chunks| chunks.map { fake_vector } }
    allow(Autonomia::Agents::EmbeddingService).to receive(:new).and_return(embedder)
    allow(Autonomia::Agents::Knowledge::DocumentClassifier).to receive(:new).and_return(classifier)
    allow(classifier).to receive(:classify).and_return(doc_classification)
  end

  describe '#perform' do
    it 'calls the DocumentClassifier exactly once for the source' do
      # Assert
      expect(Autonomia::Agents::Knowledge::DocumentClassifier).to receive(:new)
        .with(source: source, text: text).once.and_return(classifier)
      expect(classifier).to receive(:classify).once.and_return(doc_classification)

      # Act
      run!
    end

    it 'stamps deterministic per-chunk metadata (source_type + heading + material_type + keywords)' do
      # Act
      run!

      # Assert
      meta = source.reload.knowledge_entries.order(:chunk_index).first.metadata
      expect(meta).to include(
        'source_type' => 'pdf', 'section_heading' => 'POLITICA DE REEMBOLSO', 'material_type' => 'prose'
      )
      expect(meta['keywords']).to include('reembolso')
    end

    it 'stamps the document classification (doc.topics/entities/style) on the chunk metadata' do
      # Act
      run!

      # Assert
      doc = source.reload.knowledge_entries.order(:chunk_index).first.metadata['doc']
      expect(doc).to eq('topics' => ['Reembolso'], 'entities' => ['Plano Plus'], 'style' => 'formal')
    end

    it 'embeds the chunk TEXT (heading-inherited), one vector per chunk' do
      # Assert — o embedder recebe strings, não hashes; e o texto carrega o cabeçalho herdado.
      expect(embedder).to receive(:embed_batch) do |chunks|
        expect(chunks).to all(be_a(String))
        expect(chunks.first).to start_with('POLITICA DE REEMBOLSO')
        chunks.map { fake_vector }
      end

      # Act
      run!
    end

    it 'raises EmptyExtraction and writes nothing when extraction is empty' do
      # Arrange
      allow(processor).to receive(:extract).and_return('   ')

      # Act / Assert
      expect { run! }.to raise_error(described_class::EmptyExtraction)
      expect(source.reload.knowledge_entries.count).to eq(0)
    end

    it 'still ingests when the classifier degrades to empty (best-effort)' do
      # Arrange — classificação vazia (IA indisponível): metadata.doc fica com listas vazias, mas os
      # entries são gravados normalmente (a classificação nunca bloqueia a ingestão).
      allow(classifier).to receive(:classify).and_return(topics: [], entities: [], doc_style: nil)

      # Act
      count = run!

      # Assert
      expect(count).to be >= 1
      meta = source.reload.knowledge_entries.first.metadata
      expect(meta.dig('doc', 'topics')).to eq([])
      expect(meta.dig('doc', 'style')).to be_nil
    end
  end

  # B1 — com o modelo 3-large ativo, o Ingestor grava na coluna halfvec `embedding_large` (SQL cru) e
  # deixa a coluna legada `embedding` (vector 1536) NULL — a base fica pronta p/ o cutover sem misturar.
  describe '#perform with the large embedding model active' do
    before do
      allow(Autonomia::Agents::Config).to receive(:active_embedding_model).and_return('text-embedding-3-large')
      allow(embedder).to receive(:embed_batch) { |chunks| chunks.map { Array.new(3072, 0.01) } }
    end

    it 'writes to embedding_large (halfvec) and leaves the legacy embedding NULL' do
      # Act
      run!

      # Assert
      entry = source.reload.knowledge_entries.order(:chunk_index).first
      expect(entry.read_attribute(:embedding)).to be_nil
      populated = Autonomia::Agents::KnowledgeEntry.where(id: entry.id).where.not(embedding_large: nil).count
      expect(populated).to eq(1)
    end
  end
end
