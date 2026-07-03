require 'rails_helper'

RSpec.describe Autonomia::Agents::Knowledge::Processors::Pdf do
  subject(:processor) { described_class.new(source) }

  # ActiveStorage delega #download dinamicamente (method_missing -> blob); verified double não o vê.
  let(:source) { double('source', reference: 'doc.pdf', file: file) } # rubocop:disable RSpec/VerifiedDoubles
  let(:file) { double('attachment', attached?: true, download: 'pdf-bytes') } # rubocop:disable RSpec/VerifiedDoubles
  let(:reader) { instance_double(PDF::Reader) }

  # Stub do PDF::Reader (lib externa): páginas com o texto dado. with_tempfile (real) roda com um
  # tempfile de bytes falsos — o reader é stubado, então o conteúdo do arquivo não importa.
  def stub_pages(page_texts)
    pages = page_texts.map { |text| instance_double(PDF::Reader::Page, text: text) }
    allow(PDF::Reader).to receive(:new).and_return(reader)
    allow(reader).to receive(:pages).and_return(pages)
  end

  describe '#extract' do
    it 'concatenates the text of every page for a text-layer PDF' do
      # Arrange
      stub_pages(['Primeira pagina com bastante texto', 'Segunda pagina tambem'])

      # Act
      result = processor.extract

      # Assert
      expect(result).to include('Primeira pagina com bastante texto')
      expect(result).to include('Segunda pagina tambem')
    end

    context 'when the text layer is near-empty (scanned PDF)' do
      # Stub da pilha de OCR (libs externas mini_magick + rtesseract) p/ não exigir binários.
      def stub_ocr(text)
        # MiniMagick::Image expõe `density` via method_missing (opções do imagemagick), então
        # um double simples é mais fiel que um verified double aqui.
        image = double('mm_image', path: '/tmp/page-0.png', density: nil) # rubocop:disable RSpec/VerifiedDoubles
        allow(MiniMagick::Image).to receive(:open).and_return(image)
        allow(image).to receive(:pages).and_return([image])
        rtesseract = instance_double(RTesseract, to_s: text)
        allow(RTesseract).to receive(:new).and_return(rtesseract)
      end

      it 'falls back to OCR and returns the OCR text' do
        # Arrange
        stub_pages([' ']) # abaixo de OCR_MIN_CHARS -> dispara OCR
        stub_ocr('TEXTO RECONHECIDO VIA OCR DO SCAN')

        # Act
        result = processor.extract

        # Assert
        expect(result).to eq('TEXTO RECONHECIDO VIA OCR DO SCAN')
      end

      it 'returns the empty text gracefully when the OCR stack is unavailable' do
        # Arrange
        stub_pages(['']) # dispara OCR
        allow(MiniMagick::Image).to receive(:open).and_raise(StandardError.new('imagemagick missing'))
        allow(Rails.logger).to receive(:warn)

        # Act
        result = processor.extract

        # Assert
        expect(result.strip).to eq('')
        expect(Rails.logger).to have_received(:warn).with(/pdf_ocr_unavailable/)
      end

      it 'keeps the original text when OCR also yields near-empty output' do
        # Arrange
        stub_pages(['x'])
        stub_ocr('  ')

        # Act
        result = processor.extract

        # Assert — OCR quase-vazio: devolve o texto original bruto (extração normal não é stripada)
        expect(result).to eq("x\n")
      end
    end

    it 'raises ExtractionError on a malformed PDF' do
      # Arrange
      allow(PDF::Reader).to receive(:new).and_raise(PDF::Reader::MalformedPDFError.new('boom'))

      # Act / Assert
      expect { processor.extract }.to raise_error(described_class::ExtractionError, /pdf_parse_failed/)
    end
  end
end
