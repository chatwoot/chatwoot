module ImageProcessing
  # Implements a chainable interface for building processing options.
  module Chainable
    # Specify the source image file.
    def source(file)
      branch source: file
    end

    # Specify the output format.
    def convert(format)
      branch format: format
    end

    # Specify processor options applied when loading the image.
    def loader(**options)
      branch loader: options
    end

    # Specify processor options applied when saving the image.
    def saver(**options)
      branch saver: options
    end

    # Register instrumentation block that will be called around the pipeline.
    def instrumenter(&block)
      branch instrumenter: block
    end

    # Add multiple operations as a hash or an array.
    #
    #   .apply(resize_to_limit: [400, 400], strip: true)
    #   # or
    #   .apply([[:resize_to_limit, [400, 400]], [:strip, true])
    def apply(operations)
      operations.inject(self) do |builder, (name, argument)|
        if argument == true || argument == nil
          builder.public_send(name)
        elsif argument.is_a?(Array)
          builder.public_send(name, *argument)
        elsif argument.is_a?(Hash)
          builder.public_send(name, **argument)
        else
          builder.public_send(name, argument)
        end
      end
    end

    # Add an operation defined by the processor.
    def operation(name, *args, &block)
      branch operations: [[name, args, *block]]
    end

    # Call the defined processing and get the result. Allows specifying
    # the source file and destination.
    def call(file = nil, destination: nil, **call_options)
      options = {}
      options[:source] = file if file
      options[:destination] = destination if destination

      branch(**options).call!(**call_options)
    end

    # Creates a new builder object, merging current options with new options.
    def branch(**new_options)
      if self.is_a?(Builder)
        options = self.options
      else
        options = DEFAULT_OPTIONS.merge(processor: self::Processor)
      end

      options = options.merge(new_options) do |key, old_value, new_value|
        case key
        when :loader, :saver then old_value.merge(new_value)
        when :operations     then old_value + new_value
        else                      new_value
        end
      end

      Builder.new(options.freeze)
    end

    private

    # Assume that any unknown method names an operation supported by the
    # processor. Add a bang ("!") if you want processing to be performed.
    def method_missing(name, *args, &block)
      return super if name.to_s.end_with?("?")
      return send(name.to_s.chomp("!"), *args, &block).call if name.to_s.end_with?("!")

      operation(name, *args, &block)
    end
    ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)

    # Empty options which the builder starts with.
    DEFAULT_OPTIONS = {
      source:     nil,
      loader:     {},
      saver:      {},
      format:     nil,
      operations: [],
      processor:  nil,
    }.freeze
  end
end
