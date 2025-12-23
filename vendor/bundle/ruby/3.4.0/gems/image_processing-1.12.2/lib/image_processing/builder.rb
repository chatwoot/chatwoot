module ImageProcessing
  class Builder
    include Chainable

    attr_reader :options

    def initialize(options)
      @options = options
    end

    # Calls the pipeline to perform the processing from built options.
    def call!(**call_options)
      instrument do
        Pipeline.new(pipeline_options).call(**call_options)
      end
    end

    private

    def instrument
      return yield unless options[:instrumenter]

      result = nil
      options[:instrumenter].call(**pipeline_options) { result = yield }
      result
    end

    def pipeline_options
      options.reject { |key, _| key == :instrumenter }
    end
  end
end
