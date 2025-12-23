# frozen_string_literal: true

module Haml
  module AttributeBuilder
    # https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
    INVALID_ATTRIBUTE_NAME_REGEX = /[ \0"'>\/=]/

    class << self
      def build(class_id, obj_ref, is_html, attr_wrapper, escape_attrs, hyphenate_data_attrs, *attributes_hashes)
        attributes = class_id
        attributes_hashes.each do |old|
          result = {}
          old.each { |k, v| result[k.to_s] = v }
          merge_attributes!(attributes, result)
        end
        merge_attributes!(attributes, parse_object_ref(obj_ref)) if obj_ref
        build_attributes(is_html, attr_wrapper, escape_attrs, hyphenate_data_attrs, attributes)
      end

      def build_attributes(is_html, attr_wrapper, escape_attrs, hyphenate_data_attrs, attributes = {})
        # @TODO this is an absolutely ridiculous amount of arguments. At least
        # some of this needs to be moved into an instance method.
        join_char = hyphenate_data_attrs ? '-' : '_'

        attributes.each do |key, value|
          if value.is_a?(Hash)
            data_attributes = attributes.delete(key)
            data_attributes = flatten_data_attributes(data_attributes, '', join_char)
            data_attributes = build_data_keys(data_attributes, hyphenate_data_attrs, key)
            verify_attribute_names!(data_attributes.keys)
            attributes = data_attributes.merge(attributes)
          end
        end

        result = attributes.collect do |attr, value|
          next if value.nil?

          value = filter_and_join(value, ' ') if attr == 'class'
          value = filter_and_join(value, '_') if attr == 'id'

          if value == true
            next " #{attr}" if is_html
            next " #{attr}=#{attr_wrapper}#{attr}#{attr_wrapper}"
          elsif value == false
            next
          end

          value =
            if escape_attrs == :once
              Haml::Helpers.escape_once_without_haml_xss(value.to_s)
            elsif escape_attrs
              Haml::Helpers.html_escape_without_haml_xss(value.to_s)
            else
              value.to_s
            end
          " #{attr}=#{attr_wrapper}#{value}#{attr_wrapper}"
        end
        result.compact!
        result.sort!
        result.join
      end

      # @return [String, nil]
      def filter_and_join(value, separator)
        return '' if (value.respond_to?(:empty?) && value.empty?)

        if value.is_a?(Array)
          value = value.flatten
          value.map! {|item| item ? item.to_s : nil}
          value.compact!
          value = value.join(separator)
        else
          value = value ? value.to_s : nil
        end
        !value.nil? && !value.empty? && value
      end

      # Merges two attribute hashes.
      # This is the same as `to.merge!(from)`,
      # except that it merges id, class, and data attributes.
      #
      # ids are concatenated with `"_"`,
      # and classes are concatenated with `" "`.
      # data hashes are simply merged.
      #
      # Destructively modifies `to`.
      #
      # @param to [{String => String,Hash}] The attribute hash to merge into
      # @param from [{String => Object}] The attribute hash to merge from
      # @return [{String => String,Hash}] `to`, after being merged
      def merge_attributes!(to, from)
        from.keys.each do |key|
          to[key] = merge_value(key, to[key], from[key])
        end
        to
      end

      # Merge multiple values to one attribute value. No destructive operation.
      #
      # @param key [String]
      # @param values [Array<Object>]
      # @return [String,Hash]
      def merge_values(key, *values)
        values.inject(nil) do |to, from|
          merge_value(key, to, from)
        end
      end

      def verify_attribute_names!(attribute_names)
        attribute_names.each do |attribute_name|
          if attribute_name =~ INVALID_ATTRIBUTE_NAME_REGEX
            raise InvalidAttributeNameError.new("Invalid attribute name '#{attribute_name}' was rendered")
          end
        end
      end

      private

      # Merge a couple of values to one attribute value. No destructive operation.
      #
      # @param to [String,Hash,nil]
      # @param from [Object]
      # @return [String,Hash]
      def merge_value(key, to, from)
        if from.kind_of?(Hash) || to.kind_of?(Hash)
          from = { nil => from } if !from.is_a?(Hash)
          to   = { nil => to }   if !to.is_a?(Hash)
          to.merge(from)
        elsif key == 'id'
          merged_id = filter_and_join(from, '_')
          if to && merged_id
            merged_id = "#{to}_#{merged_id}"
          elsif to || merged_id
            merged_id ||= to
          end
          merged_id
        elsif key == 'class'
          merged_class = filter_and_join(from, ' ')
          if to && merged_class
            merged_class = (to.split(' ') | merged_class.split(' ')).join(' ')
          elsif to || merged_class
            merged_class ||= to
          end
          merged_class
        else
          from
        end
      end

      def build_data_keys(data_hash, hyphenate, attr_name="data")
        Hash[data_hash.map do |name, value|
          if name == nil
            [attr_name, value]
          elsif hyphenate
            ["#{attr_name}-#{name.to_s.tr('_', '-')}", value]
          else
            ["#{attr_name}-#{name}", value]
          end
        end]
      end

      def flatten_data_attributes(data, key, join_char, seen = [])
        return {key => data} unless data.is_a?(Hash)

        return {key => nil} if seen.include? data.object_id
        seen << data.object_id

        data.sort {|x, y| x[0].to_s <=> y[0].to_s}.inject({}) do |hash, (k, v)|
          joined = key == '' ? k : [key, k].join(join_char)
          hash.merge! flatten_data_attributes(v, joined, join_char, seen)
        end
      end

      # Takes an array of objects and uses the class and id of the first
      # one to create an attributes hash.
      # The second object, if present, is used as a prefix,
      # just like you can do with `dom_id()` and `dom_class()` in Rails
      def parse_object_ref(ref)
        prefix = ref[1]
        ref = ref[0]
        # Let's make sure the value isn't nil. If it is, return the default Hash.
        return {} if ref.nil?
        class_name =
          if ref.respond_to?(:haml_object_ref)
            ref.haml_object_ref
          else
            underscore(ref.class)
          end
        ref_id =
          if ref.respond_to?(:to_key)
            key = ref.to_key
            key.join('_') unless key.nil?
          else
            ref.id
          end
        id = "#{class_name}_#{ref_id || 'new'}"
        if prefix
          class_name = "#{ prefix }_#{ class_name}"
          id = "#{ prefix }_#{ id }"
        end

        { 'id'.freeze => id, 'class'.freeze => class_name }
      end

      # Changes a word from camel case to underscores.
      # Based on the method of the same name in Rails' Inflector,
      # but copied here so it'll run properly without Rails.
      def underscore(camel_cased_word)
        word = camel_cased_word.to_s.dup
        word.gsub!(/::/, '_')
        word.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        word.tr!('-', '_')
        word.downcase!
        word
      end
    end
  end
end
