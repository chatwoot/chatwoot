# frozen_string_literal: true

require "dry/initializer"
require "dry/schema/constants"

module Dry
  module Schema
    # Compiles rule results AST into human-readable format
    #
    # @api private
    class MessageCompiler
      extend ::Dry::Initializer

      resolve_key_predicate = proc { |node, opts|
        *arg_vals, val = node.map(&:last)
        [[*opts.path, arg_vals[0]], arg_vals[1..arg_vals.size - 1], val]
      }

      resolve_predicate = proc { |node, opts|
        [Array(opts.path), *node.map(&:last)]
      }

      DEFAULT_PREDICATE_RESOLVERS = ::Hash
        .new(resolve_predicate).update(key?: resolve_key_predicate).freeze

      EMPTY_OPTS = VisitorOpts.new
      EMPTY_MESSAGE_SET = MessageSet.new(EMPTY_ARRAY).freeze
      FULL_MESSAGE_WHITESPACE = ::Hash.new(" ").merge(
        ja: "",
        zh: "",
        bn: "",
        th: "",
        lo: "",
        my: ""
      )

      param :messages

      option :full, default: -> { false }
      option :locale, default: -> { :en }
      option :predicate_resolvers, default: -> { DEFAULT_PREDICATE_RESOLVERS }

      attr_reader :options

      attr_reader :default_lookup_options

      # @api private
      def initialize(messages, **options)
        super
        @options = options
        @default_lookup_options = options[:locale] ? {locale: locale} : EMPTY_HASH
      end

      # @api private
      def with(new_options)
        return self if new_options.empty?

        updated_opts = options.merge(new_options)

        return self if updated_opts.eql?(options)

        self.class.new(messages, **updated_opts)
      end

      # @api private
      def call(ast)
        return EMPTY_MESSAGE_SET if ast.empty?

        current_messages = EMPTY_ARRAY.dup
        compiled_messages = ast.map { |node| visit(node, EMPTY_OPTS.dup(current_messages)) }

        MessageSet[compiled_messages, failures: options.fetch(:failures, true)]
      end

      # @api private
      def visit(node, opts = EMPTY_OPTS.dup)
        __send__(:"visit_#{node[0]}", node[1], opts)
      end

      # @api private
      def visit_failure(node, opts)
        rule, other = node
        visit(other, opts.(rule: rule))
      end

      # @api private
      def visit_hint(*)
        nil
      end

      # @api private
      def visit_not(node, opts)
        visit(node, opts.(not: true))
      end

      # @api private
      def visit_and(node, opts)
        left, right = node.map { |n| visit(n, opts) }

        if right
          [left, right]
        else
          left
        end
      end

      # @api private
      def visit_unexpected_key(node, opts)
        visit_predicate([:unexpected_key, []], opts.dup.update(path: Path[node.first]))
      end

      # @api private
      def visit_or(node, opts)
        left, right = node.map { |n| visit(n, opts) }
        Message::Or[left, right, or_translator]
      end

      # @api private
      def or_translator
        @or_translator ||= proc { |k|
          message = messages.translate(k, **default_lookup_options)
          message.is_a?(Hash) ? message[:text] : message
        }
      end

      # @api private
      def visit_namespace(node, opts)
        ns, rest = node
        self.class.new(messages.namespaced(ns), **options).visit(rest, opts)
      end

      # @api private
      def visit_predicate(node, opts)
        predicate, args = node

        tokens = message_tokens(args)
        path, *arg_vals, input = predicate_resolvers[predicate].(args, opts)

        options = opts.dup.update(
          path: path.last, **tokens, **lookup_options(arg_vals: arg_vals, input: input)
        ).to_h

        template, meta = messages[predicate, options]

        unless template
          raise MissingMessageError.new(path, messages.looked_up_paths(predicate, options))
        end

        text = message_text(template, tokens, options)

        message_type(options).new(
          text: text,
          meta: meta,
          path: path,
          predicate: predicate,
          args: arg_vals,
          input: input
        )
      end

      # @api private
      def message_type(*)
        Message
      end

      # @api private
      def visit_key(node, opts)
        name, other = node
        visit(other, opts.(path: name))
      end

      # @api private
      def visit_set(node, opts)
        node.map { |el| visit(el, opts) }
      end

      # @api private
      def visit_implication(node, *args)
        _, right = node
        visit(right, *args)
      end

      # @api private
      def visit_xor(node, opts)
        left, right = node
        [visit(left, opts), visit(right, opts)].uniq
      end

      # @api private
      def lookup_options(arg_vals:, input:)
        default_lookup_options.merge(
          arg_type: arg_vals.size == 1 && arg_vals[0].class,
          val_type: input.equal?(Undefined) ? ::NilClass : input.class
        )
      end

      # @api private
      def message_text(template, tokens, options)
        text = template[template.data(tokens)]

        return text if !text || !full

        rule = options[:path]
        [messages.rule(rule, options) || rule,
         text].join(FULL_MESSAGE_WHITESPACE[template.options[:locale]])
      end

      # @api private
      def message_tokens(args)
        tokens = args.each_with_object({}) do |arg, hash|
          case arg[1]
          when ::Array, ::Set
            hash[arg[0]] = arg[1].join(LIST_SEPARATOR)
          when ::Range
            hash[:"#{arg[0]}_left"] = arg[1].first
            hash[:"#{arg[0]}_right"] = arg[1].last
          else
            hash[arg[0]] = arg[1]
          end
        end
        args.any? { |e| e.first == :size } ? append_mapped_size_tokens(tokens) : tokens
      end

      # @api private
      def append_mapped_size_tokens(tokens)
        # this is a temporary fix for the inconsistency in the "size" errors arguments
        mapped_hash = tokens.each_with_object({}) { |(k, v), h|
          h[k.to_s.gsub("size", "num").to_sym] = v
        }
        tokens.merge(mapped_hash)
      end
    end
  end
end
