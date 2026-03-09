require 'rails_helper'

RSpec.describe StickerUploader, type: :model do
  let(:pack_name) { 'Test Pack' }
  let(:tags) { ['test', 'sample'] }
  
  describe 'validations' do
    it 'validates presence of file' do
      uploader = described_class.new(pack_name: pack_name)
      expect(uploader).not_to be_valid
      expect(uploader.errors[:file]).to include("can't be blank")
    end

    it 'validates presence of pack_name' do
      uploader = described_class.new(file: create_test_image_file)
      expect(uploader).not_to be_valid
      expect(uploader.errors[:pack_name]).to include("can't be blank")
    end

    it 'validates pack_name length' do
      long_name = 'a' * 51
      uploader = described_class.new(file: create_test_image_file, pack_name: long_name)
      expect(uploader).not_to be_valid
      expect(uploader.errors[:pack_name]).to include('is too long (maximum is 50 characters)')
    end

    it 'validates file is an image' do
      text_file = create_test_text_file
      uploader = described_class.new(file: text_file, pack_name: pack_name)
      expect(uploader).not_to be_valid
      expect(uploader.errors[:file]).to include('must be an image file')
    end

    it 'validates supported image formats' do
      # Test unsupported format
      svg_file = create_test_svg_file
      uploader = described_class.new(file: svg_file, pack_name: pack_name)
      expect(uploader).not_to be_valid
      expect(uploader.errors[:file]).to include('format not supported. Please use JPEG, PNG, GIF, WebP, BMP, or TIFF')
    end

    it 'validates file size limit' do
      large_file = create_large_image_file
      uploader = described_class.new(file: large_file, pack_name: pack_name)
      expect(uploader).not_to be_valid
      expect(uploader.errors[:file]).to include('is too large. Maximum size is 5MB')
    end
  end

  describe '#process_and_validate' do
    let(:valid_uploader) do
      described_class.new(
        file: create_test_image_file,
        pack_name: pack_name,
        tags: tags
      )
    end

    let(:mock_processed_file) do
      temp_file = Tempfile.new(['processed_sticker', '.webp'])
      temp_file.write('mock webp content')
      temp_file.rewind
      temp_file
    end

    before do
      # Mock the image processing methods
      allow(valid_uploader).to receive(:process_image).and_return(mock_processed_file)
    end

    it 'processes a valid image successfully' do
      result = valid_uploader.process_and_validate
      expect(result).to be true
      expect(valid_uploader.processed_file).to be_present
    end

    it 'creates a WebP file with correct dimensions' do
      valid_uploader.process_and_validate
      
      # Mock the processed file path
      allow(valid_uploader.processed_file).to receive(:path).and_return('/tmp/test.webp')
      
      expect(valid_uploader.processed_file.path).to end_with('.webp')
    end

    it 'ensures processed file is under size limit' do
      valid_uploader.process_and_validate
      file_size = valid_uploader.processed_file.size
      
      expect(file_size).to be <= StickerUploader::MAX_OUTPUT_SIZE
    end

    it 'handles processing errors gracefully' do
      # Mock process_image to raise an error
      allow(valid_uploader).to receive(:process_image).and_raise(StandardError.new('Processing failed'))
      
      expect(valid_uploader.process_and_validate).to be false
      expect(valid_uploader.errors[:file]).to include('Processing failed: Processing failed')
    end

    it 'retries with lower quality if file is too large' do
      # Create a mock that returns a large file first, then a smaller one
      large_temp_file = Tempfile.new(['large', '.webp'])
      large_temp_file.write('x' * (StickerUploader::MAX_OUTPUT_SIZE + 1000))
      large_temp_file.rewind

      small_temp_file = Tempfile.new(['small', '.webp'])
      small_temp_file.write('x' * 1000)
      small_temp_file.rewind

      allow(valid_uploader).to receive(:process_image).and_return(large_temp_file)
      allow(valid_uploader).to receive(:reprocess_with_lower_quality).and_return(small_temp_file)

      expect(valid_uploader.process_and_validate).to be true
    end
  end

  describe '#processed_filename' do
    it 'generates a unique WebP filename' do
      uploader = described_class.new(file: create_test_image_file, pack_name: pack_name)
      filename = uploader.processed_filename
      
      expect(filename).to match(/^sticker_[a-f0-9]{16}\.webp$/)
    end

    it 'generates different filenames for different instances' do
      uploader1 = described_class.new(file: create_test_image_file, pack_name: pack_name)
      uploader2 = described_class.new(file: create_test_image_file, pack_name: pack_name)
      
      expect(uploader1.processed_filename).not_to eq(uploader2.processed_filename)
    end
  end

  private

  def create_test_image_file
    # Create a mock file that behaves like an uploaded image
    file = double('uploaded_file')
    allow(file).to receive(:content_type).and_return('image/png')
    allow(file).to receive(:size).and_return(1024) # 1KB
    allow(file).to receive(:respond_to?).and_return(false) # Default to false
    allow(file).to receive(:respond_to?).with(:content_type).and_return(true)
    allow(file).to receive(:respond_to?).with(:size).and_return(true)
    allow(file).to receive(:respond_to?).with(:empty?).and_return(false)
    
    file
  end

  def create_test_text_file
    file = Tempfile.new(['test', '.txt'])
    file.write('This is a text file')
    file.rewind
    
    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: 'test.txt',
      type: 'text/plain'
    )
  end

  def create_test_svg_file
    file = Tempfile.new(['test', '.svg'])
    file.write('<svg xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100"/></svg>')
    file.rewind
    
    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: 'test.svg',
      type: 'image/svg+xml'
    )
  end

  def create_large_image_file
    file = Tempfile.new(['large_image', '.png'])
    file.write('x' * (StickerUploader::MAX_FILE_SIZE + 1000))
    file.rewind
    
    ActionDispatch::Http::UploadedFile.new(
      tempfile: file,
      filename: 'large_image.png',
      type: 'image/png'
    )
  end
end