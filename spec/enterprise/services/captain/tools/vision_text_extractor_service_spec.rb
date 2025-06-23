require 'rails_helper'

RSpec.describe Captain::Tools::VisionTextExtractorService do
  let(:image_path) { '/tmp/test_image.png' }

  describe 'when Google Vision is available' do
    subject { described_class.new }

    let(:mock_vision) { double('vision_client') }
    let(:mock_response) { double('response', error: nil) }
    let(:mock_text_annotation) { double('text_annotation', text: 'Vision extracted text') }

    before do
      allow(Google::Cloud::Vision).to receive(:image_annotator).and_return(mock_vision)
      allow(Google::Cloud::Vision::Image).to receive(:new).with(image_path).and_return(double('image'))
      allow(mock_vision).to receive(:text_detection).and_return(mock_response)
      allow(mock_response).to receive(:full_text_annotation).and_return(mock_text_annotation)
    end

    describe '#extract_text_from_image' do
      it 'uses Vision API for text extraction' do
        result = subject.extract_text_from_image(image_path)
        expect(result).to eq('Vision extracted text')
      end

      context 'when Vision API returns error' do
        before do
          allow(mock_response).to receive(:error).and_return(double('error', message: 'API Error'))
        end

        it 'raises TextExtractionError' do
          expect { subject.extract_text_from_image(image_path) }.to raise_error(
            Captain::Tools::VisionTextExtractorService::TextExtractionError,
            /Vision API error/
          )
        end
      end
    end
  end

  describe 'when Google Vision is not available' do
    subject { described_class.new }

    let(:mock_tesseract) { double('tesseract', to_s: 'Tesseract extracted text') }

    before do
      allow(Google::Cloud::Vision).to receive(:image_annotator).and_raise(StandardError.new('No credentials'))
      allow(RTesseract).to receive(:new).with(image_path).and_return(mock_tesseract)
    end

    describe '#extract_text_from_image' do
      it 'falls back to Tesseract for text extraction' do
        result = subject.extract_text_from_image(image_path)
        expect(result).to eq('Tesseract extracted text')
      end

      context 'when Tesseract fails' do
        before do
          allow(RTesseract).to receive(:new).and_raise(StandardError.new('Tesseract error'))
        end

        it 'raises TextExtractionError' do
          expect { subject.extract_text_from_image(image_path) }.to raise_error(
            Captain::Tools::VisionTextExtractorService::TextExtractionError,
            /Failed to extract text with Tesseract/
          )
        end
      end
    end
  end

  describe '#extract_text_from_multiple_images' do
    let(:image_paths) { ['/tmp/image1.png', '/tmp/image2.png'] }
    
    before do
      allow(Google::Cloud::Vision).to receive(:image_annotator).and_return(double('vision'))
      allow(subject).to receive(:extract_text_from_image).with('/tmp/image1.png').and_return('Text from page 1')
      allow(subject).to receive(:extract_text_from_image).with('/tmp/image2.png').and_return('Text from page 2')
    end

    it 'extracts text from multiple images and joins them' do
      result = subject.extract_text_from_multiple_images(image_paths)
      expect(result).to eq("Text from page 1\n\nText from page 2")
    end

    it 'skips empty results' do
      allow(subject).to receive(:extract_text_from_image).with('/tmp/image2.png').and_return('')
      
      result = subject.extract_text_from_multiple_images(image_paths)
      expect(result).to eq('Text from page 1')
    end

    it 'logs which extraction method is being used' do
      expect(Rails.logger).to receive(:info).with(/Using (Google Vision|Tesseract) for text extraction/)
      subject.extract_text_from_multiple_images(image_paths)
    end
  end
end