require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Processors::Json do
  subject(:processor) { described_class.new(source) }

  # Fonte mínima: só precisa responder a #file.attached? e #file.download (usado por download_bytes).
  # ActiveStorage delega #download dinamicamente (method_missing -> blob), então um verified double
  # não enxerga o método; usamos doubles simples p/ o anexo e a fonte.
  let(:source) { double('source', file: file) } # rubocop:disable RSpec/VerifiedDoubles
  let(:file) { double('attachment', attached?: true) } # rubocop:disable RSpec/VerifiedDoubles

  def stub_json(data)
    allow(file).to receive(:download).and_return(data.to_json)
  end

  describe '#extract' do
    # RECALL-CRÍTICO (P1.1a/P1.2): cada objeto vira UMA linha com TODOS os campos-folha juntos, p/ o
    # Chunker (1 chunk por linha-registro) manter o fato composto (nome<->preço) num único chunk. Sem
    # isso, "Quanto custa o Notebook Pro 15" recuperaria o nome SEM o preço.
    it 'keeps all leaf fields of one object on a single grouped line (composite fact)' do
      # Arrange
      stub_json('produtos' => [{ 'nome' => 'Notebook Pro 15', 'sku' => 'NB-15', 'preco' => 4999 }])

      # Act
      lines = processor.extract.split("\n")

      # Assert — nome e preço na MESMA linha (um chunk), não em linhas separadas
      product_line = lines.find { |l| l.include?('Notebook Pro 15') }
      expect(product_line).to include('Notebook Pro 15').and include('4999')
      expect(lines.count { |l| l.include?('Notebook Pro 15') }).to eq(1)
    end

    it 'emits one grouped line per object in an array' do
      # Arrange
      stub_json('faq' => [{ 'p' => 'Tem frete?', 'r' => 'Grátis acima de 200' },
                          { 'p' => 'Troca?', 'r' => 'Em 7 dias' }])

      # Act
      lines = processor.extract.split("\n")

      # Assert
      expect(lines.size).to eq(2)
      expect(lines[0]).to include('Tem frete?').and include('Grátis acima de 200')
    end

    it 'groups nested-object scalars under a dotted label' do
      # Arrange
      stub_json('empresa' => { 'endereco' => { 'cidade' => 'Recife', 'uf' => 'PE' } })

      # Act
      lines = processor.extract.split("\n")

      # Assert — cidade e uf juntas sob o rótulo pontuado
      line = lines.find { |l| l.start_with?('empresa.endereco:') }
      expect(line).to include('Recife').and include('PE')
    end

    it 'joins a scalar array into a single comma-separated field on the entry line' do
      # Arrange — array escalar de topo entra como campo agrupado (entry_field: "chave a, b, c")
      stub_json('tags' => %w[frete troca garantia])

      # Act / Assert
      expect(processor.extract).to eq('tags frete, troca, garantia')
    end

    it 'raises ExtractionError on invalid JSON' do
      # Arrange
      allow(file).to receive(:download).and_return('{ not json')

      # Act / Assert
      expect { processor.extract }.to raise_error(described_class::ExtractionError, /invalid_json/)
    end
  end
end
