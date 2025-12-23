# frozen_string_literal: true

require "dry/types/printer/composition"

module Dry
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/PerceivedComplexity
  module Types
    # @api private
    class Printer
      MAPPING = {
        Nominal => :visit_nominal,
        Constructor => :visit_constructor,
        [
          Constrained,
          Constrained::Coercible
        ] => :visit_constrained,
        Types::Hash => :visit_hash,
        Schema => :visit_schema,
        Schema::Key => :visit_key,
        Map => :visit_map,
        Array => :visit_array,
        Array::Member => :visit_array_member,
        Lax => :visit_lax,
        Enum => :visit_enum,
        [Default, Default::Callable] => :visit_default,
        [
          Sum,
          Sum::Constrained,
          Intersection,
          Intersection::Constrained,
          Implication,
          Implication::Constrained
        ] => :visit_composition,
        Any.class => :visit_any
      }.flat_map { |k, v| Array(k).map { |kk| [kk, v] } }.to_h

      def initialize
        @composition_printers = {}
        freeze
      end

      def call(type)
        output = "".dup
        visit(type) { |str| output << str }
        "#<Dry::Types[#{output}]>"
      end

      def visit(type, &)
        print_with = MAPPING.fetch(type.class) do
          if type.class < Constructor
            :visit_constructor
          elsif type.is_a?(Type)
            return yield type.inspect
          else
            raise ArgumentError, "Do not know how to print #{type.class}"
          end
        end
        send(print_with, type, &)
      end

      def visit_any(_) = yield "Any"

      def visit_array(type)
        visit_options(EMPTY_HASH, type.meta) do |opts|
          yield "Array#{opts}"
        end
      end

      def visit_array_member(array)
        visit(array.member) do |type|
          visit_options(EMPTY_HASH, array.meta) do |opts|
            yield "Array<#{type}#{opts}>"
          end
        end
      end

      def visit_constructor(constructor)
        visit(constructor.type) do |type|
          visit_callable(constructor.fn.fn) do |fn|
            options = constructor.options.dup
            options.delete(:fn)

            visit_options(options) do |opts|
              yield "Constructor<#{type} fn=#{fn}#{opts}>"
            end
          end
        end
      end

      def visit_constrained(constrained)
        visit(constrained.type) do |type|
          options = constrained.options.dup
          rule = options.delete(:rule)

          visit_options(options) do |_opts|
            yield "Constrained<#{type} rule=[#{rule}]>"
          end
        end
      end

      def visit_composition(composition, &)
        klass = composition.class
        @composition_printers[klass] = Composition.new(self, klass)
        @composition_printers[klass].visit(composition, &)
      end

      def visit_enum(enum)
        visit(enum.type) do |type|
          options = enum.options.dup
          mapping = options.delete(:mapping)

          visit_options(options) do |opts|
            if mapping == enum.inverted_mapping
              yield "Enum(#{enum.joined_values})<#{type}#{opts}>"
            else
              mapping_str = mapping.map { |key, value|
                "#{key.inspect}=>#{value.inspect}"
              }.join(", ")
              yield "Enum<#{type} mapping={#{mapping_str}}#{opts}>"
            end
          end
        end
      end

      def visit_default(default)
        visit(default.type) do |type|
          visit_options(default.options) do |opts|
            if default.is_a?(Default::Callable)
              visit_callable(default.value) do |fn|
                yield "Default<#{type} value_fn=#{fn}#{opts}>"
              end
            else
              yield "Default<#{type} value=#{default.value.inspect}#{opts}>"
            end
          end
        end
      end

      def visit_nominal(type)
        visit_options(type.options, type.meta) do |opts|
          yield "Nominal<#{type.primitive}#{opts}>"
        end
      end

      def visit_lax(lax)
        visit(lax.type) do |type|
          yield "Lax<#{type}>"
        end
      end

      def visit_callable(callable)
        fn = callable.is_a?(String) ? FnContainer[callable] : callable

        case fn
        when ::Method
          yield "#{fn.receiver}.#{fn.name}"
        when ::Proc
          path, line = fn.source_location

          if line&.zero?
            yield ".#{path}"
          elsif path
            yield "#{path.sub("#{Dir.pwd}/", EMPTY_STRING)}:#{line}"
          else
            match = fn.to_s.match(/\A#<Proc:0x\h+\(&:(?<name>\w+)\)(:? \(lambda\))?>\z/) # rubocop:disable Lint/MixedRegexpCaptureTypes

            if match
              yield ".#{match[:name]}"
            elsif fn.lambda?
              yield "(lambda)"
            else
              yield "(proc)"
            end
          end
        else
          call = fn.method(:call)

          if call.owner == fn.class
            yield "#{fn.class}#call"
          else
            yield "#{fn}.call"
          end
        end
      end

      def visit_schema(schema)
        options = schema.options.dup
        size = schema.count
        key_fn_str = ""
        type_fn_str = ""
        strict_str = ""

        strict_str = "strict " if options.delete(:strict)

        if (key_fn = options.delete(:key_transform_fn))
          visit_callable(key_fn) do |fn|
            key_fn_str = "key_fn=#{fn} "
          end
        end

        if (type_fn = options.delete(:type_transform_fn))
          visit_callable(type_fn) do |fn|
            type_fn_str = "type_fn=#{fn} "
          end
        end

        keys = options.delete(:keys)

        visit_options(options, schema.meta) do |opts|
          opts = "#{opts[1..]} " unless opts.empty?
          schema_parameters = "#{key_fn_str}#{type_fn_str}#{strict_str}#{opts}"

          header = "Schema<#{schema_parameters}keys={"

          if size.zero?
            yield "#{header}}>"
          else
            yield header.dup << keys.map { |key|
              visit(key) { |type| type }
            }.join(" ") << "}>"
          end
        end
      end

      def visit_map(map)
        visit(map.key_type) do |key|
          visit(map.value_type) do |value|
            options = map.options.dup
            options.delete(:key_type)
            options.delete(:value_type)

            visit_options(options) do |_opts|
              yield "Map<#{key} => #{value}>"
            end
          end
        end
      end

      def visit_key(key)
        visit(key.type) do |type|
          if key.required?
            yield "#{key.name}: #{type}"
          else
            yield "#{key.name}?: #{type}"
          end
        end
      end

      def visit_hash(hash)
        options = hash.options.dup
        type_fn_str = ""

        if (type_fn = options.delete(:type_transform_fn))
          visit_callable(type_fn) do |fn|
            type_fn_str = "type_fn=#{fn}"
          end
        end

        visit_options(options, hash.meta) do |opts|
          if opts.empty? && type_fn_str.empty?
            yield "Hash"
          else
            yield "Hash<#{type_fn_str}#{opts}>"
          end
        end
      end

      def visit_options(options, meta = EMPTY_HASH) # rubocop:disable Metrics/PerceivedComplexity
        if options.empty? && meta.empty?
          yield ""
        else
          opts = options.empty? ? "" : " options=#{options.inspect}"

          if meta.empty?
            yield opts
          else
            values = meta.map do |key, value|
              case key
              when Symbol
                "#{key}: #{value.inspect}"
              else
                "#{key.inspect}=>#{value.inspect}"
              end
            end

            yield "#{opts} meta={#{values.join(", ")}}"
          end
        end
      end
    end

    PRINTER = Printer.new
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/PerceivedComplexity
end
