# frozen_string_literal: true
require 'sprockets/file_reader'
require 'sprockets/mime'
require 'sprockets/processor_utils'
require 'sprockets/uri_utils'
require 'sprockets/utils'

module Sprockets
  # `Processing` is an internal mixin whose public methods are exposed on
  # the `Environment` and `CachedEnvironment` classes.
  module Processing
    include ProcessorUtils, URIUtils, Utils

    def pipelines
      config[:pipelines]
    end

    # Registers a pipeline that will be called by `call_processor` method.
    def register_pipeline(name, proc = nil, &block)
      proc ||= block

      self.config = hash_reassoc(config, :pipeline_exts) do |pipeline_exts|
        pipeline_exts.merge(".#{name}".freeze => name.to_sym)
      end

      self.config = hash_reassoc(config, :pipelines) do |pipelines|
        pipelines.merge(name.to_sym => proc)
      end
    end

    # Preprocessors are ran before Postprocessors and Engine
    # processors.
    def preprocessors
      config[:preprocessors]
    end
    alias_method :processors, :preprocessors

    # Postprocessors are ran after Preprocessors and Engine processors.
    def postprocessors
      config[:postprocessors]
    end

    # Registers a new Preprocessor `klass` for `mime_type`.
    #
    #     register_preprocessor 'text/css', Sprockets::DirectiveProcessor
    #
    # A block can be passed for to create a shorthand processor.
    #
    #     register_preprocessor 'text/css' do |input|
    #       input[:data].gsub(...)
    #     end
    #
    def register_preprocessor(*args, &block)
      register_config_processor(:preprocessors, *args, &block)
      compute_transformers!(self.config[:registered_transformers])
    end
    alias_method :register_processor, :register_preprocessor

    # Registers a new Postprocessor `klass` for `mime_type`.
    #
    #     register_postprocessor 'application/javascript', Sprockets::DirectiveProcessor
    #
    # A block can be passed for to create a shorthand processor.
    #
    #     register_postprocessor 'application/javascript' do |input|
    #       input[:data].gsub(...)
    #     end
    #
    def register_postprocessor(*args, &block)
      register_config_processor(:postprocessors, *args, &block)
      compute_transformers!(self.config[:registered_transformers])
    end

    # Remove Preprocessor `klass` for `mime_type`.
    #
    #     unregister_preprocessor 'text/css', Sprockets::DirectiveProcessor
    #
    def unregister_preprocessor(*args)
      unregister_config_processor(:preprocessors, *args)
      compute_transformers!(self.config[:registered_transformers])
    end
    alias_method :unregister_processor, :unregister_preprocessor

    # Remove Postprocessor `klass` for `mime_type`.
    #
    #     unregister_postprocessor 'text/css', Sprockets::DirectiveProcessor
    #
    def unregister_postprocessor(*args)
      unregister_config_processor(:postprocessors, *args)
      compute_transformers!(self.config[:registered_transformers])
    end

    # Bundle Processors are ran on concatenated assets rather than
    # individual files.
    def bundle_processors
      config[:bundle_processors]
    end

    # Registers a new Bundle Processor `klass` for `mime_type`.
    #
    #     register_bundle_processor  'application/javascript', Sprockets::DirectiveProcessor
    #
    # A block can be passed for to create a shorthand processor.
    #
    #     register_bundle_processor 'application/javascript' do |input|
    #       input[:data].gsub(...)
    #     end
    #
    def register_bundle_processor(*args, &block)
      register_config_processor(:bundle_processors, *args, &block)
    end

    # Remove Bundle Processor `klass` for `mime_type`.
    #
    #     unregister_bundle_processor 'application/javascript', Sprockets::DirectiveProcessor
    #
    def unregister_bundle_processor(*args)
      unregister_config_processor(:bundle_processors, *args)
    end

    # Public: Register bundle metadata reducer function.
    #
    # Examples
    #
    #   Sprockets.register_bundle_metadata_reducer 'application/javascript', :jshint_errors, [], :+
    #
    #   Sprockets.register_bundle_metadata_reducer 'text/css', :selector_count, 0 { |total, count|
    #     total + count
    #   }
    #
    # mime_type - String MIME Type. Use '*/*' applies to all types.
    # key       - Symbol metadata key
    # initial   - Initial memo to pass to the reduce function (default: nil)
    # block     - Proc accepting the memo accumulator and current value
    #
    # Returns nothing.
    def register_bundle_metadata_reducer(mime_type, key, *args, &block)
      case args.size
      when 0
        reducer = block
      when 1
        if block_given?
          initial = args[0]
          reducer = block
        else
          initial = nil
          reducer = args[0].to_proc
        end
      when 2
        initial = args[0]
        reducer = args[1].to_proc
      else
        raise ArgumentError, "wrong number of arguments (#{args.size} for 0..2)"
      end

      self.config = hash_reassoc(config, :bundle_reducers, mime_type) do |reducers|
        reducers.merge(key => [initial, reducer])
      end
    end

    protected
      def resolve_processors_cache_key_uri(uri)
        params = parse_uri_query_params(uri[11..-1])
        processors = processors_for(params[:type], params[:file_type], params[:pipeline])
        processors_cache_keys(processors)
      end

      def build_processors_uri(type, file_type, pipeline)
        query = encode_uri_query_params(
          type: type,
          file_type: file_type,
          pipeline: pipeline
        )
        "processors:#{query}"
      end

      def processors_for(type, file_type, pipeline)
        pipeline ||= :default
        if fn = config[:pipelines][pipeline.to_sym]
          fn.call(self, type, file_type)
        else
          raise Error, "no pipeline: #{pipeline}"
        end
      end

      def default_processors_for(type, file_type)
        bundled_processors = config[:bundle_processors][type]
        if bundled_processors.any?
          bundled_processors
        else
          self_processors_for(type, file_type)
        end
      end

      def self_processors_for(type, file_type)
        processors = []

        processors.concat config[:postprocessors][type]
        if type != file_type && processor = config[:transformers][file_type][type]
          processors << processor
        end
        processors.concat config[:preprocessors][file_type]

        if processors.any? || mime_type_charset_detecter(type)
          processors << FileReader
        end

        processors
      end

    private
      def register_config_processor(type, mime_type, processor = nil, &block)
        processor ||= block

        self.config = hash_reassoc(config, type, mime_type) do |processors|
          processors.unshift(processor)
          processors
        end
      end

      def unregister_config_processor(type, mime_type, processor)
        self.config = hash_reassoc(config, type, mime_type) do |processors|
          processors.delete_if { |p| p == processor || p.class == processor }
          processors
        end
      end
  end
end
