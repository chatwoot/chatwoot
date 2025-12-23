# frozen_string_literal: true
require 'sprockets/http_utils'
require 'sprockets/processor_utils'
require 'sprockets/utils'

module Sprockets
  module Transformers
    include HTTPUtils, ProcessorUtils, Utils

    # Public: Two level mapping of a source mime type to a target mime type.
    #
    #   environment.transformers
    #   # => { 'text/coffeescript' => {
    #            'application/javascript' => ConvertCoffeeScriptToJavaScript
    #          }
    #        }
    #
    def transformers
      config[:transformers]
    end

    Transformer = Struct.new :from, :to, :proc

    # Public: Register a transformer from and to a mime type.
    #
    # from - String mime type
    # to   - String mime type
    # proc - Callable block that accepts an input Hash.
    #
    # Examples
    #
    #   register_transformer 'text/coffeescript', 'application/javascript',
    #     ConvertCoffeeScriptToJavaScript
    #
    #   register_transformer 'image/svg+xml', 'image/png', ConvertSvgToPng
    #
    # Returns nothing.
    def register_transformer(from, to, proc)
      self.config = hash_reassoc(config, :registered_transformers) do |transformers|
        transformers << Transformer.new(from, to, proc)
      end
      compute_transformers!(self.config[:registered_transformers])
    end

    # Internal: Register transformer for existing type adding a suffix.
    #
    # types       - Array of existing mime type Strings
    # type_format - String suffix formatting string
    # extname     - String extension to append
    # processor   - Callable block that accepts an input Hash.
    #
    # Returns nothing.
    def register_transformer_suffix(types, type_format, extname, processor)
      Array(types).each do |type|
        extensions, charset = mime_types[type].values_at(:extensions, :charset)
        parts = type.split('/')
        suffix_type = type_format.sub('\1', parts[0]).sub('\2', parts[1])
        extensions = extensions.map { |ext| "#{ext}#{extname}" }

        register_mime_type(suffix_type, extensions: extensions, charset: charset)
        register_transformer(suffix_type, type, processor)
      end
    end

    # Internal: Resolve target mime type that the source type should be
    # transformed to.
    #
    # type   - String from mime type
    # accept - String accept type list (default: '*/*')
    #
    # Examples
    #
    #   resolve_transform_type('text/plain', 'text/plain')
    #   # => 'text/plain'
    #
    #   resolve_transform_type('image/svg+xml', 'image/png, image/*')
    #   # => 'image/png'
    #
    #   resolve_transform_type('text/css', 'image/png')
    #   # => nil
    #
    # Returns String mime type or nil is no type satisfied the accept value.
    def resolve_transform_type(type, accept)
      find_best_mime_type_match(accept || '*/*', [type].compact + config[:transformers][type].keys)
    end

    # Internal: Expand accept type list to include possible transformed types.
    #
    # parsed_accepts - Array of accept q values
    #
    # Examples
    #
    #   expand_transform_accepts([['application/javascript', 1.0]])
    #   # => [['application/javascript', 1.0], ['text/coffeescript', 0.8]]
    #
    # Returns an expanded Array of q values.
    def expand_transform_accepts(parsed_accepts)
      accepts = []
      parsed_accepts.each do |(type, q)|
        accepts.push([type, q])
        config[:inverted_transformers][type].each do |subtype|
          accepts.push([subtype, q * 0.8])
        end
      end
      accepts
    end

    # Internal: Compose multiple transformer steps into a single processor
    # function.
    #
    # transformers - Two level Hash of a source mime type to a target mime type
    # types - Array of mime type steps
    #
    # Returns Processor.
    def compose_transformers(transformers, types, preprocessors, postprocessors)
      if types.length < 2
        raise ArgumentError, "too few transform types: #{types.inspect}"
      end

      processors = types.each_cons(2).map { |src, dst|
        unless processor = transformers[src][dst]
          raise ArgumentError, "missing transformer for type: #{src} to #{dst}"
        end
        processor
      }

      compose_transformer_list processors, preprocessors, postprocessors
    end

    private
      def compose_transformer_list(transformers, preprocessors, postprocessors)
        processors = []

        transformers.each do |processor|
          processors.concat postprocessors[processor.from]
          processors << processor.proc
          processors.concat preprocessors[processor.to]
        end

        if processors.size > 1
          compose_processors(*processors.reverse)
        elsif processors.size == 1
          processors.first
        end
      end

      def compute_transformers!(registered_transformers)
        preprocessors         = self.config[:preprocessors]
        postprocessors        = self.config[:postprocessors]
        transformers          = Hash.new { {} }
        inverted_transformers = Hash.new { Set.new }
        incoming_edges        = registered_transformers.group_by(&:from)

        registered_transformers.each do |t|
          traversals = dfs_paths([t]) { |k| incoming_edges.fetch(k.to, []) }

          traversals.each do |nodes|
            src, dst = nodes.first.from, nodes.last.to
            processor = compose_transformer_list nodes, preprocessors, postprocessors

            transformers[src] = {} unless transformers.key?(src)
            transformers[src][dst] = processor

            inverted_transformers[dst] = Set.new unless inverted_transformers.key?(dst)
            inverted_transformers[dst] << src
          end
        end

        self.config = hash_reassoc(config, :transformers) { transformers }
        self.config = hash_reassoc(config, :inverted_transformers) { inverted_transformers }
      end
  end
end
