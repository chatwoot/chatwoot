require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Processors::Json do
  subject(:processor) { described_class.new(source) }

  # Fonte mínima: só precisa responder a #file.attached? e #file.download (usado por download_bytes).
  # ActiveStorage delega #download dinamicamente (method_missing -> blob), então um verified double
  # não enxerga o método; usamos doubles simples p/ o anexo e a fonte.
  let(:source) { double('source', file: file) } # rubocop:disable RSpec/VerifiedDoubles
  let(:file) { double('attachment', attached?: true) } # rubocop:disable RSpec/VerifiedDoubles

  def stub_json(hash)
    allow(file).to receive(:download).and_return(hash.to_json)
  end

  describe '#extract' do
    it 'flattens nested objects into path.to.key: value leaf lines' do
      # Arrange
      stub_json('empresa' => { 'endereco' => { 'cidade' => 'Recife', 'uf' => 'PE' } })

      # Act
      lines = processor.extract.split("\n")

      # Assert
      expect(lines).to include('empresa.endereco.cidade: Recife')
      expect(lines).to include('empresa.endereco.uf: PE')
    end

    it 'indexes objects inside arrays by position in the path' do
      # Arrange
      stub_json('itens' => [{ 'sku' => 'NB-15', 'preco' => 4999 }])

      # Act
      lines = processor.extract.split("\n")

      # Assert
      expect(lines).to include('itens.0.sku: NB-15')
      expect(lines).to include('itens.0.preco: 4999')
    end

    it 'joins a scalar array into a single comma-separated line' do
      # Arrange
      stub_json('tags' => %w[frete troca garantia])

      # Act
      result = processor.extract

      # Assert
      expect(result).to eq('tags: frete, troca, garantia')
    end

    it 'caps large object arrays and notes the omitted count' do
      # Arrange
      big = Array.new(described_class::ARRAY_CAP + 5) { |i| { 'id' => i } }
      stub_json('produtos' => big)

      # Act
      lines = processor.extract.split("\n")

      # Assert
      expect(lines).to include('produtos.0.id: 0')
      expect(lines).not_to include("produtos.#{described_class::ARRAY_CAP}.id: #{described_class::ARRAY_CAP}")
      expect(lines).to include('produtos: (+5 itens omitidos)')
    end

    it 'raises ExtractionError on invalid JSON' do
      # Arrange
      allow(file).to receive(:download).and_return('{ not json')

      # Act / Assert
      expect { processor.extract }.to raise_error(described_class::ExtractionError, /invalid_json/)
    end
  end
end
