# frozen_string_literal: true

require "set"
require "concurrent/map"

require "dry/schema/constants"

module Dry
  module Schema
    module Messages
      # Abstract class for message backends
      #
      # @api public
      class Abstract
        include ::Dry::Configurable
        include ::Dry::Equalizer(:config)

        setting :default_locale
        setting :load_paths, default: ::Set[DEFAULT_MESSAGES_PATH]
        setting :top_namespace, default: DEFAULT_MESSAGES_ROOT
        setting :root, default: "errors"
        setting :lookup_options, default: %i[root predicate path val_type arg_type].freeze

        setting :lookup_paths, default: [
          "%<root>s.rules.%<path>s.%<predicate>s.arg.%<arg_type>s",
          "%<root>s.rules.%<path>s.%<predicate>s",
          "%<root>s.%<predicate>s.%<message_type>s",
          "%<root>s.%<predicate>s.value.%<path>s",
          "%<root>s.%<predicate>s.value.%<val_type>s.arg.%<arg_type>s",
          "%<root>s.%<predicate>s.value.%<val_type>s",
          "%<root>s.%<predicate>s.arg.%<arg_type>s",
          "%<root>s.%<predicate>s"
        ].freeze

        setting :rule_lookup_paths, default: ["rules.%<name>s"].freeze

        setting :arg_types, default: ::Hash.new { |*| "default" }.update(
          ::Range => "range"
        )

        setting :val_types, default: ::Hash.new { |*| "default" }.update(
          ::Range => "range",
          ::String => "string"
        )

        # @api private
        def self.setting_names
          @setting_names ||= settings.map { _1.name.to_sym }
        end

        # @api private
        def self.build(options = EMPTY_HASH)
          messages = new

          messages.configure do |config|
            options.each do |key, value|
              config.public_send(:"#{key}=", value)
            end

            config.root = "#{config.top_namespace}.#{config.root}"

            config.rule_lookup_paths = config.rule_lookup_paths.map { |path|
              "#{config.top_namespace}.#{path}"
            }

            yield(config) if block_given?
          end

          messages.prepare
        end

        # @api private
        def translate(key, locale: default_locale)
          t["#{config.top_namespace}.#{key}", locale: locale]
        end

        # @api private
        def rule(name, options = {})
          tokens = {name: name, locale: options.fetch(:locale, default_locale)}
          path = rule_lookup_paths(tokens).detect { |key| key?(key, options) }

          rule = get(path, options) if path
          rule.is_a?(::Hash) ? rule[:text] : rule
        end

        # Retrieve a message template
        #
        # @return [Template]
        #
        # @api public
        def call(predicate, options)
          options = {locale: default_locale, **options}
          opts = options.reject { |k,| config.lookup_options.include?(k) }
          path = lookup_paths(predicate, options).detect { |key| key?(key, opts) }

          return unless path

          result = get(path, opts)

          [
            Template.new(
              messages: self,
              key: path,
              options: opts
            ),
            result[:meta]
          ]
        end

        alias_method :[], :call

        # Check if given key is defined
        #
        # @return [Boolean]
        #
        # @api public
        def key?(_key, _options = EMPTY_HASH)
          raise ::NotImplementedError
        end

        # Retrieve an array of looked up paths
        #
        # @param [Symbol] predicate
        # @param [Hash] options
        #
        # @return [String]
        #
        # @api public
        def looked_up_paths(predicate, options)
          tokens = lookup_tokens(predicate, options)
          filled_lookup_paths(tokens)
        end

        # @api private
        def lookup_paths(predicate, options)
          tokens = lookup_tokens(predicate, options)
          filled_lookup_paths(tokens)
        end

        # @api private
        def filled_lookup_paths(tokens)
          config.lookup_paths.map { |path| path % tokens }
        end

        # @api private
        def rule_lookup_paths(tokens)
          config.rule_lookup_paths.map { |key| key % tokens }
        end

        # Return a new message backend that will look for messages under provided namespace
        #
        # @param [Symbol,String] namespace
        #
        # @api public
        def namespaced(namespace)
          Dry::Schema::Messages::Namespaced.new(namespace, self)
        end

        # Return root path to messages file
        #
        # @return [Pathname]
        #
        # @api public
        def root
          config.root
        end

        # @api private
        def default_locale
          config.default_locale
        end

        # @api private
        def interpolatable_data(_key, _options, **_data)
          raise ::NotImplementedError
        end

        # @api private
        def interpolate(_key, _options, **_data)
          raise ::NotImplementedError
        end

        private

        # @api private
        def lookup_tokens(predicate, options)
          options.merge(
            predicate: predicate,
            root: options[:not] ? "#{root}.not" : root,
            arg_type: config.arg_types[options[:arg_type]],
            val_type: config.val_types[options[:val_type]],
            message_type: options[:message_type] || :failure
          )
        end

        # @api private
        def custom_top_namespace?(path)
          path.to_s == DEFAULT_MESSAGES_PATH.to_s && config.top_namespace != DEFAULT_MESSAGES_ROOT
        end
      end
    end
  end
end
