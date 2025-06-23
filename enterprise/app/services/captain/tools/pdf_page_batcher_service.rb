require 'mini_magick'

class Captain::Tools::PdfPageBatcherService
  PAGES_PER_BATCH = 3
  
  def initialize(temp_files_tracker)
    @temp_files = temp_files_tracker
  end

  def batch_pages(image_files)
    return image_files if image_files.length <= PAGES_PER_BATCH
    
    batched_images = []
    
    image_files.each_slice(PAGES_PER_BATCH) do |batch|
      if batch.length == 1
        # Single page, use as-is
        batched_images << batch.first
      else
        # Multiple pages, combine them
        combined_image = combine_images(batch)
        batched_images << combined_image
      end
    end
    
    batched_images
  end

  private

  def combine_images(image_paths)
    # Create a vertical montage of the images
    output_path = create_temp_file_path('.png')
    
    MiniMagick::Tool::Montage.new do |montage|
      image_paths.each { |path| montage << path }
      montage.tile('1x')  # Arrange in single column (vertically)
      montage.geometry('+0+10')  # Add 10px spacing between images
      montage.background('white')
      montage << output_path
    end
    
    @temp_files << output_path
    output_path
  rescue StandardError => e
    Rails.logger.error "Failed to combine images: #{e.message}"
    # Fallback to first image if combining fails
    image_paths.first
  end

  def create_temp_file_path(extension)
    temp_file = Tempfile.new(['combined_pages', extension])
    temp_file.close
    @temp_files << temp_file
    temp_file.path
  end
end