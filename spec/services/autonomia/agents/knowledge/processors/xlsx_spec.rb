require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Processors::Xlsx do
  subject(:processor) { described_class.new(source) }

  # Fonte com anexo ActiveStorage falso: with_tempfile (real) escreve o download num tempfile.
  # ActiveStorage delega #download dinamicamente (method_missing -> blob); verified double não o vê.
  let(:source) { double('source', reference: 'planilha.xlsx', file: file) } # rubocop:disable RSpec/VerifiedDoubles
  let(:file) { double('attachment', attached?: true, download: 'xlsx-bytes') } # rubocop:disable RSpec/VerifiedDoubles
  let(:book) { instance_double(Roo::Excelx) }

  def stub_book(sheets)
    allow(Roo::Spreadsheet).to receive(:open).and_return(book)
    allow(book).to receive(:sheets).and_return(sheets.keys)
    sheets.each do |name, rows|
      sheet = instance_double(Roo::Excelx, to_a: rows)
      allow(book).to receive(:sheet).with(name).and_return(sheet)
    end
  end

  describe '#extract' do
    it 'prefixes each sheet block with the sheet name as a markdown heading' do
      # Arrange
      stub_book('Produtos' => [%w[sku preco], %w[NB-15 4999]])

      # Act
      result = processor.extract

      # Assert
      expect(result).to eq("## Produtos\nsku | preco\nNB-15 | 4999")
    end

    it 'keeps sheet context across multiple sheets' do
      # Arrange
      stub_book('Frete' => [['gratis acima de 200']], 'Trocas' => [['ate 7 dias']])

      # Act
      lines = processor.extract.split("\n")

      # Assert
      expect(lines).to eq(['## Frete', 'gratis acima de 200', '## Trocas', 'ate 7 dias'])
    end

    it 'skips empty sheets so no orphan heading is emitted' do
      # Arrange
      stub_book('Vazia' => [], 'Dados' => [['x']])

      # Act
      result = processor.extract

      # Assert
      expect(result).to eq("## Dados\nx")
    end

    it 'raises ExtractionError when roo fails to parse' do
      # Arrange
      allow(Roo::Spreadsheet).to receive(:open).and_raise(Roo::Error.new('boom'))

      # Act / Assert
      expect { processor.extract }.to raise_error(described_class::ExtractionError, /xlsx_parse_failed/)
    end
  end
end
