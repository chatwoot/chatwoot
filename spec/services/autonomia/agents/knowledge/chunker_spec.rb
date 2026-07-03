require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Chunker do
  let(:chunk_max) { Autonomia::Agents::Config::CHUNK_MAX }

  describe '#chunks' do
    context 'when a section has a short heading followed by a body longer than CHUNK_MAX' do
      it 'prepends the heading to every chunk generated from the body' do
        # Arrange
        heading = 'POLITICA DE REEMBOLSO'
        sentence = 'O reembolso e processado em ate trinta dias uteis apos a solicitacao formal do cliente. '
        body = sentence * 20 # ~1780 chars, bem acima de CHUNK_MAX
        document = "#{heading}\n\n#{body}"

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks.size).to be > 1
        expect(chunks).to all(start_with(heading))
      end
    end

    context 'when the first body chunk already contains the heading' do
      it 'does not duplicate the heading' do
        # Arrange
        heading = '47- CANCELAMENTO DE VIAGEM PLUS REASON'
        body = 'Garante reembolso caso o segurado precise cancelar a viagem por motivo imprevisto.'
        document = "#{heading}\n\n#{body}"

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks.size).to eq(1)
        expect(chunks.first.scan(heading).size).to eq(1)
        expect(chunks.first).to start_with(heading)
      end
    end

    context 'with a tabular/record paragraph and no heading' do
      it 'keeps emitting one chunk per record, unchanged' do
        # Arrange
        records = [
          'Nome: Joao Silva de Souza',
          'Cargo: Analista de Suporte',
          'Cidade: Sao Paulo capital'
        ]
        document = records.join("\n")

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks).to eq(records)
      end
    end

    context 'with a prose document without headings' do
      it 'keeps the original one-chunk-per-paragraph behavior' do
        # Arrange
        paragraphs = [
          'O frete gratis vale para compras acima de noventa e nove reais em todo o Brasil.',
          'As trocas podem ser feitas em ate trinta dias corridos apos o recebimento do pedido.'
        ]
        document = paragraphs.join("\n\n")

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(chunks).to eq(paragraphs)
      end
    end

    context 'with the real policy section (numbered heading + body over 2x CHUNK_MAX)' do
      it 'makes the section name searchable in every body chunk without exceeding CHUNK_MAX' do
        # Arrange
        heading = '47- CANCELAMENTO DE VIAGEM PLUS REASON'
        motive = 'Morte do segurado ou de parentes proximos comprovada por documento oficial emitido em cartorio. '
        body = motive * 15 # ~1470 chars, acima de 2x CHUNK_MAX (600)
        document = "#{heading}\n\n#{body}"

        # Act
        chunks = described_class.new(document).chunks

        # Assert
        expect(body.length).to be > (2 * chunk_max)
        expect(chunks.size).to be >= 3
        expect(chunks).to all(include('PLUS REASON'))
        expect(chunks.map { |chunk| chunk.scan(heading).size }).to all(eq(1))
        expect(chunks.map(&:length)).to all(be <= chunk_max)
      end
    end
  end
end
