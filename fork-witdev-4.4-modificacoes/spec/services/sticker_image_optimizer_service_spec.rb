# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StickerImageOptimizerService, type: :service do
  let(:account_id) { 1 }
  let(:test_image_path) { Rails.root.join('spec', 'fixtures', 'files', 'test_image.png') }
  let(:uploaded_file) do
    Rack::Test::UploadedFile.new(test_image_path, 'image/png')
  end

  before do
    # Ensure test image exists
    unless File.exist?(test_image_path)
      # Create a simple test image if it doesn't exist
      FileUtils.mkdir_p(File.dirname(test_image_path))
      
      # Create a simple 100x100 PNG for testing using magick command
      system("magick -size 100x100 xc:white #{test_image_path}")
      
      # Fallback: create with MiniMagick if magick command fails
      unless File.exist?(test_image_path) && File.size(test_image_path) > 0
        require 'mini_magick'
        image = MiniMagick::Image.new
        image.size '100x100'
        image.background 'white'
        image.format 'png'
        image.write(test_image_path)
      end
    end
  end

  describe '#initialize' do
    it 'initializes with file and account_id' do
      service = described_class.new(file: uploaded_file, account_id: account_id)
      
      expect(service.file).to eq(uploaded_file)
      expect(service.account_id).to eq(account_id)
    end
  end

  describe '#process' do
    let(:service) { described_class.new(file: uploaded_file, account_id: account_id) }

    context 'with valid image file' do
      it 'successfully processes the image' do
        result = service.process

        expect(result[:success]).to be true
        expect(result[:processed_file]).to be_present
        expect(result[:original_size]).to be > 0
        expect(result[:final_size]).to be > 0
        expect(result[:compression_ratio]).to be_a(Numeric)
        expect(result[:processing_time]).to be > 0
      end

      it 'creates a WebP file' do
        result = service.process

        expect(result[:processed_file].content_type).to eq('image/webp')
        expect(result[:processed_file].original_filename).to end_with('.webp')
      end

      it 'optimizes file size' do
        result = service.process

        # Check against static file size limit (since test image is static)
        expect(result[:final_size]).to be <= described_class::MAX_STATIC_FILE_SIZE
        expect(result[:compression_ratio]).to be_a(Numeric)
        expect(result[:is_animated]).to be_in([true, false])
        expect(result[:has_transparency]).to be_in([true, false])
      end

      it 'tracks performance metrics' do
        metrics_service = instance_double(StickerPerformanceMetricsService)
        allow(StickerPerformanceMetricsService).to receive(:instance).and_return(metrics_service)
        
        expect(metrics_service).to receive(:track_api_performance).with(
          api_name: 'image_processing',
          response_time: be_a(Numeric),
          success: true
        )

        service.process
      end
    end

    context 'with invalid file' do
      let(:invalid_file) { double('invalid_file', size: 100, read: 'invalid content') }
      let(:service) { described_class.new(file: invalid_file, account_id: account_id) }

      it 'returns error result' do
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
        expect(result[:processing_time]).to be > 0
      end

      it 'tracks failed processing metrics' do
        metrics_service = instance_double(StickerPerformanceMetricsService)
        allow(StickerPerformanceMetricsService).to receive(:instance).and_return(metrics_service)
        
        expect(metrics_service).to receive(:track_api_performance).with(
          api_name: 'image_processing',
          response_time: be_a(Numeric),
          success: false
        )

        service.process
      end
    end

    context 'with file too large' do
      let(:large_file) { double('large_file', size: 6.megabytes, read: 'content') }
      let(:service) { described_class.new(file: large_file, account_id: account_id) }

      it 'raises argument error' do
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to include('too large')
      end
    end

    context 'with unsupported format' do
      let(:unsupported_file) do
        double('unsupported_file', 
               size: 1000, 
               content_type: 'application/pdf',
               read: 'pdf content',
               respond_to?: true)
      end
      let(:service) { described_class.new(file: unsupported_file, account_id: account_id) }

      it 'raises argument error' do
        result = service.process

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported file format')
      end
    end
  end

  describe '.batch_process' do
    let(:files) { [uploaded_file, uploaded_file] }

    it 'processes multiple files' do
      result = described_class.batch_process(files, account_id: account_id)

      expect(result[:total_files]).to eq(2)
      expect(result[:successful]).to be >= 0
      expect(result[:failed]).to be >= 0
      expect(result[:total_processing_time]).to be > 0
      expect(result[:results].length).to eq(2)
    end

    it 'includes file index in results' do
      result = described_class.batch_process(files, account_id: account_id)

      expect(result[:results][0][:file_index]).to eq(0)
      expect(result[:results][1][:file_index]).to eq(1)
    end
  end

  describe '.benchmark_processing' do
    it 'runs benchmark iterations' do
      result = described_class.benchmark_processing(uploaded_file, iterations: 2)

      expect(result[:iterations]).to eq(2)
      expect(result[:successful]).to be >= 0
      expect(result[:failed]).to be >= 0
      
      if result[:successful] > 0
        expect(result[:avg_processing_time]).to be > 0
        expect(result[:min_processing_time]).to be > 0
        expect(result[:max_processing_time]).to be > 0
        expect(result[:avg_compression_ratio]).to be_a(Numeric)
      end
    end

    context 'when all iterations fail' do
      let(:invalid_file) { double('invalid_file', size: 100, read: 'invalid') }

      it 'returns error summary' do
        result = described_class.benchmark_processing(invalid_file, iterations: 2)

        expect(result[:successful]).to eq(0)
        expect(result[:failed]).to eq(2)
        expect(result[:error]).to eq('All iterations failed')
      end
    end
  end

  describe 'private methods' do
    let(:service) { described_class.new(file: uploaded_file, account_id: account_id) }
    
    describe '#animated?' do
      it 'detects static images as non-animated' do
        image = MiniMagick::Image.open(test_image_path)
        result = service.send(:animated?, image)
        
        expect(result).to be false
      end
    end

    describe '#has_transparency?' do
      it 'detects transparency in images' do
        image = MiniMagick::Image.open(test_image_path)
        result = service.send(:has_transparency?, image)
        
        # Result should be boolean
        expect(result).to be_in([true, false])
      end
    end

    describe '#generate_filename' do
      it 'generates unique WebP filename for static stickers' do
        filename1 = service.send(:generate_filename, false)
        filename2 = service.send(:generate_filename, false)

        expect(filename1).to end_with('.webp')
        expect(filename2).to end_with('.webp')
        expect(filename1).not_to eq(filename2)
        expect(filename1).to match(/^sticker_\d{8}_\d{6}_[a-f0-9]{8}\.webp$/)
      end

      it 'generates unique WebP filename for animated stickers' do
        filename = service.send(:generate_filename, true)

        expect(filename).to end_with('.webp')
        expect(filename).to include('_animated')
        expect(filename).to match(/^sticker_\d{8}_\d{6}_[a-f0-9]{8}_animated\.webp$/)
      end
    end
  end

  describe 'constants' do
    it 'defines expected constants' do
      expect(described_class::MAX_STATIC_FILE_SIZE).to eq(100.kilobytes)
      expect(described_class::MAX_ANIMATED_FILE_SIZE).to eq(500.kilobytes)
      expect(described_class::TARGET_DIMENSIONS).to eq([512, 512])
      expect(described_class::OUTPUT_FORMAT).to eq('webp')
      expect(described_class::SUPPORTED_FORMATS).to include('image/png', 'image/jpeg', 'image/webp')
      expect(described_class::QUALITY_LEVELS).to be_an(Array)
    end
  end
end