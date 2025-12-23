# frozen_string_literal: true

require 'haml/attribute_parser'

module Haml
  class AttributeCompiler
    # @param type [Symbol] :static or :dynamic
    # @param key [String]
    # @param value [String] Actual string value for :static type, value's Ruby literal for :dynamic type.
    AttributeValue = Struct.new(:type, :key, :value)

    # @param options [Haml::Options]
    def initialize(options)
      @is_html = [:html4, :html5].include?(options[:format])
      @attr_wrapper = options[:attr_wrapper]
      @escape_attrs = options[:escape_attrs]
      @hyphenate_data_attrs = options[:hyphenate_data_attrs]
    end

    # Returns Temple expression to render attributes.
    #
    # @param attributes [Hash]
    # @param object_ref [String,:nil]
    # @param dynamic_attributes [Haml::Parser::DynamicAttributes]
    # @return [Array] Temple expression
    def compile(attributes, object_ref, dynamic_attributes)
      if object_ref != :nil || !AttributeParser.available?
        return [:dynamic, compile_runtime_build(attributes, object_ref, dynamic_attributes)]
      end

      parsed_hashes = [dynamic_attributes.new, dynamic_attributes.old].compact.map do |attribute_hash|
        unless (hash = AttributeParser.parse(attribute_hash))
          return [:dynamic, compile_runtime_build(attributes, object_ref, dynamic_attributes)]
        end
        hash
      end
      attribute_values = build_attribute_values(attributes, parsed_hashes)
      AttributeBuilder.verify_attribute_names!(attribute_values.map(&:key))

      [:multi, *group_values_for_sort(attribute_values).map { |value_group|
        compile_attribute_values(value_group)
      }]
    end

    private

    # Returns a script to render attributes on runtime.
    #
    # @param attributes [Hash]
    # @param object_ref [String,:nil]
    # @param dynamic_attributes [Haml::Parser::DynamicAttributes]
    # @return [String] Attributes rendering code
    def compile_runtime_build(attributes, object_ref, dynamic_attributes)
      arguments = [@is_html, @attr_wrapper, @escape_attrs, @hyphenate_data_attrs].map(&method(:to_literal)).join(', ')
      "::Haml::AttributeBuilder.build(#{to_literal(attributes)}, #{object_ref}, #{arguments}, #{dynamic_attributes.to_literal})"
    end

    # Build array of grouped values whose sort order may go back and forth, which is also sorted with key name.
    # This method needs to group values with the same start because it can be changed in `Haml::AttributeBuidler#build_data_keys`.
    # @param values [Array<Haml::AttributeCompiler::AttributeValue>]
    # @return [Array<Array<Haml::AttributeCompiler::AttributeValue>>]
    def group_values_for_sort(values)
      sorted_values = values.sort_by(&:key)
      [].tap do |value_groups|
        until sorted_values.empty?
          key = sorted_values.first.key
          value_group, sorted_values = sorted_values.partition { |v| v.key.start_with?(key) }
          value_groups << value_group
        end
      end
    end

    # Returns array of AttributeValue instances from static attributes and dynamic_attributes. For each key,
    # the values' order in returned value is preserved in the same order as Haml::Buffer#attributes's merge order.
    #
    # @param attributes [{ String => String }]
    # @param parsed_hashes [{ String => String }]
    # @return [Array<AttributeValue>]
    def build_attribute_values(attributes, parsed_hashes)
      [].tap do |attribute_values|
        attributes.each do |key, static_value|
          attribute_values << AttributeValue.new(:static, key, static_value)
        end
        parsed_hashes.each do |parsed_hash|
          parsed_hash.each do |key, dynamic_value|
            attribute_values << AttributeValue.new(:dynamic, key, dynamic_value)
          end
        end
      end
    end

    # Compiles attribute values with the similar key to Temple expression.
    #
    # @param values [Array<AttributeValue>] whose `key`s are partially or fully the same from left.
    # @return [Array] Temple expression
    def compile_attribute_values(values)
      if values.map(&:key).uniq.size == 1
        compile_attribute(values.first.key, values)
      else
        runtime_build(values)
      end
    end

    # @param values [Array<AttributeValue>]
    # @return [Array] Temple expression
    def runtime_build(values)
      hash_content = values.group_by(&:key).map do |key, values_for_key|
        "#{frozen_string(key)} => #{merged_value(key, values_for_key)}"
      end.join(', ')
      arguments = [@is_html, @attr_wrapper, @escape_attrs, @hyphenate_data_attrs].map(&method(:to_literal)).join(', ')
      [:dynamic, "::Haml::AttributeBuilder.build({ #{hash_content} }, nil, #{arguments})"]
    end

    # Renders attribute values statically.
    #
    # @param values [Array<AttributeValue>]
    # @return [Array] Temple expression
    def static_build(values)
      hash_content = values.group_by(&:key).map do |key, values_for_key|
        "#{frozen_string(key)} => #{merged_value(key, values_for_key)}"
      end.join(', ')

      arguments = [@is_html, @attr_wrapper, @escape_attrs, @hyphenate_data_attrs]
      code = "::Haml::AttributeBuilder.build_attributes"\
        "(#{arguments.map(&method(:to_literal)).join(', ')}, { #{hash_content} })"
      [:static, eval(code).to_s]
    end

    # @param key [String]
    # @param values [Array<AttributeValue>]
    # @return [String]
    def merged_value(key, values)
      if values.size == 1
        attr_literal(values.first)
      else
        "::Haml::AttributeBuilder.merge_values(#{frozen_string(key)}, #{values.map(&method(:attr_literal)).join(', ')})"
      end
    end

    # @param str [String]
    # @return [String]
    def frozen_string(str)
      "#{to_literal(str)}.freeze"
    end

    # Compiles attribute values for one key to Temple expression that generates ` key='value'`.
    #
    # @param key [String]
    # @param values [Array<AttributeValue>]
    # @return [Array] Temple expression
    def compile_attribute(key, values)
      if values.all? { |v| Temple::StaticAnalyzer.static?(attr_literal(v)) }
        return static_build(values)
      end

      case key
      when 'id', 'class'
        compile_id_or_class_attribute(key, values)
      else
        compile_common_attribute(key, values)
      end
    end

    # @param id_or_class [String] "id" or "class"
    # @param values [Array<AttributeValue>]
    # @return [Array] Temple expression
    def compile_id_or_class_attribute(id_or_class, values)
      var = unique_name
      [:multi,
       [:code, "#{var} = (#{merged_value(id_or_class, values)})"],
       [:case, var,
        ['Hash, Array', runtime_build([AttributeValue.new(:dynamic, id_or_class, var)])],
        ['false, nil', [:multi]],
        [:else, [:multi,
                 [:static, " #{id_or_class}=#{@attr_wrapper}"],
                 [:escape, Escapable::EscapeSafeBuffer.new(@escape_attrs), [:dynamic, var]],
                 [:static, @attr_wrapper]],
        ]
       ],
      ]
    end

    # @param key [String] Not "id" or "class"
    # @param values [Array<AttributeValue>]
    # @return [Array] Temple expression
    def compile_common_attribute(key, values)
      var = unique_name
      [:multi,
       [:code, "#{var} = (#{merged_value(key, values)})"],
       [:case, var,
        ['Hash', runtime_build([AttributeValue.new(:dynamic, key, var)])],
        ['true', true_value(key)],
        ['false, nil', [:multi]],
        [:else, [:multi,
                 [:static, " #{key}=#{@attr_wrapper}"],
                 [:escape, Escapable::EscapeSafeBuffer.new(@escape_attrs), [:dynamic, var]],
                 [:static, @attr_wrapper]],
        ]
       ],
      ]
    end

    def true_value(key)
      if @is_html
        [:static, " #{key}"]
      else
        [:static, " #{key}=#{@attr_wrapper}#{key}#{@attr_wrapper}"]
      end
    end

    def unique_name
      @unique_name ||= 0
      "_haml_attribute_compiler#{@unique_name += 1}"
    end

    # @param [Haml::AttributeCompiler::AttributeValue] attr
    def attr_literal(attr)
      case attr.type
      when :static
        to_literal(attr.value)
      when :dynamic
        attr.value
      end
    end

    # For haml/haml#972
    # @param [Object] value
    def to_literal(value)
      case value
      when true, false
        value.to_s
      else
        Haml::Util.inspect_obj(value)
      end
    end
  end
end
