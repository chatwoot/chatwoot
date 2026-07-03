require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Processors::Docx do
  subject(:processor) { described_class.new(source) }

  # Fonte com anexo falso cujos bytes são um .docx real (zip com word/document.xml) montado a partir
  # do corpo XML dado — exercita o caminho real de leitura do zip + parsing Nokogiri.
  # ActiveStorage delega #download dinamicamente (method_missing -> blob); verified double não o vê.
  let(:source) { double('source', reference: 'doc.docx', file: file) } # rubocop:disable RSpec/VerifiedDoubles
  let(:file) { double('attachment', attached?: true, download: docx_bytes) } # rubocop:disable RSpec/VerifiedDoubles
  let(:body_xml) { '' }
  let(:docx_bytes) { build_docx(body_xml) }

  def build_docx(body)
    xml = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>#{body}</w:body>
      </w:document>
    XML
    tmp = Tempfile.new(['fixture', '.docx'])
    tmp.close
    Zip::File.open(tmp.path, Zip::File::CREATE) do |zip|
      zip.get_output_stream('word/document.xml') { |out| out.write(xml) }
    end
    bytes = File.binread(tmp.path)
    tmp.unlink
    bytes
  end

  def para(text)
    "<w:p><w:r><w:t>#{text}</w:t></w:r></w:p>"
  end

  def cell(text)
    "<w:tc>#{para(text)}</w:tc>"
  end

  describe '#extract' do
    context 'with only paragraphs' do
      let(:body_xml) { "#{para('Primeiro paragrafo')}#{para('Segundo paragrafo')}" }

      it 'extracts paragraph text' do
        expect(processor.extract).to eq("Primeiro paragrafo\nSegundo paragrafo")
      end
    end

    context 'with a table' do
      let(:body_xml) do
        '<w:tbl>' \
          "<w:tr>#{cell('sku')}#{cell('preco')}</w:tr>" \
          "<w:tr>#{cell('NB-15')}#{cell('4999')}</w:tr>" \
          '</w:tbl>'
      end

      it 'emits each table row as pipe-separated cells' do
        expect(processor.extract).to eq("sku | preco\nNB-15 | 4999")
      end
    end

    context 'with paragraphs and a table interleaved' do
      let(:body_xml) do
        "#{para('Intro')}<w:tbl><w:tr>#{cell('a')}#{cell('b')}</w:tr></w:tbl>#{para('Fim')}"
      end

      it 'preserves document order and does not duplicate table cell paragraphs' do
        result = processor.extract
        expect(result).to eq("Intro\na | b\nFim")
        expect(result.scan(/\ba\b/).size).to eq(1)
      end
    end
  end
end
