require "tempfile"

module ImageProcessing
  class Pipeline
    DEFAULT_FORMAT = "jpg"

    attr_reader :loader, :saver, :format, :operations, :processor, :destination

    # Initializes the pipeline with all the processing options.
    def initialize(options)
      fail Error, "source file is not provided" unless options[:source]

      options.each do |name, value|
        instance_variable_set(:"@#{name}", value)
      end
    end

    # Determines the destination and calls the processor.
    def call(save: true)
      if save == false
        call_processor
      elsif destination
        handle_destination do
          call_processor(destination: destination)
        end
      else
        create_tempfile do |tempfile|
          call_processor(destination: tempfile.path)
        end
      end
    end

    # Retrieves the source path on disk.
    def source_path
      source if source.is_a?(String)
    end

    # Determines the appropriate destination image format.
    def destination_format
      format   = determine_format(destination) if destination
      format ||= self.format
      format ||= determine_format(source_path) if source_path

      format || DEFAULT_FORMAT
    end

    private

    def call_processor(**options)
      processor.call(
        source:     source,
        loader:     loader,
        operations: operations,
        saver:      saver,
        **options
      )
    end

    # Creates a new tempfile for the destination file, yields it, and refreshes
    # the file descriptor to get the updated file.
    def create_tempfile
      tempfile = Tempfile.new(["image_processing", ".#{destination_format}"], binmode: true)

      yield tempfile

      tempfile.open
      tempfile
    rescue
      tempfile.close! if tempfile
      raise
    end

    # In case of processing errors, both libvips and imagemagick will leave the
    # empty destination file they created, so this method makes sure it is
    # deleted in case an exception is raised on saving the image.
    def handle_destination
      destination_existed = File.exist?(destination)
      yield
    rescue
      File.delete(destination) if File.exist?(destination) && !destination_existed
      raise
    end

    # Converts the source image object into a path or the accumulator object.
    def source
      if @source.is_a?(String)
        @source
      elsif @source.respond_to?(:path)
        @source.path
      elsif @source.respond_to?(:to_path)
        @source.to_path
      else
        @source
      end
    end

    def determine_format(file_path)
      extension = File.extname(file_path)

      extension[1..-1] if extension.size > 1
    end
  end
end
