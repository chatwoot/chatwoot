module Slim
  class InvalidAttributeNameError < StandardError; end
  module Splat
    # @api private
    class Builder
     # https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
     INVALID_ATTRIBUTE_NAME_REGEX = /[ \0"'>\/=]/
      def initialize(options)
        @options = options
        @attrs = {}
      end

      def code_attr(name, escape, value)
        if delim = @options[:merge_attrs][name]
          value = Array === value ? value.join(delim) : value.to_s
          attr(name, escape_html(escape, value)) unless value.empty?
        elsif @options[:hyphen_attrs].include?(name) && Hash === value
          hyphen_attr(name, escape, value)
        elsif value != false && value != nil
          attr(name, escape_html(value != true && escape, value))
        end
      end

      def splat_attrs(splat)
        splat.each do |name, value|
          code_attr(name.to_s, true, value)
        end
      end

      def attr(name, value)
        if name =~ INVALID_ATTRIBUTE_NAME_REGEX
          raise InvalidAttributeNameError, "Invalid attribute name '#{name}' was rendered"
        end
        if @attrs[name]
          if delim = @options[:merge_attrs][name]
            @attrs[name] += delim + value.to_s
          else
            raise("Multiple #{name} attributes specified")
          end
        else
          @attrs[name] = value
        end
      end

      def build_tag(&block)
        tag = @attrs.delete('tag').to_s
        tag = @options[:default_tag] if tag.empty?
        if block
          # This is a bit of a hack to get a universal capturing.
          #
          # TODO: Add this as a helper somewhere to solve these capturing issues
          # once and for all.
          #
          # If we have Slim capturing disabled and the scope defines the method `capture` (i.e. Rails)
          # we use this method to capture the content.
          #
          # otherwise we just use normal Slim capturing (yield).
          #
          # See https://github.com/slim-template/slim/issues/591
          #     https://github.com/slim-template/slim#helpers-capturing-and-includes
          #
          content =
            if @options[:disable_capture] && (scope = block.binding.eval('self')).respond_to?(:capture)
              scope.capture(&block)
            else
              yield
            end
          "<#{tag}#{build_attrs}>#{content}</#{tag}>"
        else
          "<#{tag}#{build_attrs} />"
        end
      end

      def build_attrs
        attrs = @options[:sort_attrs] ? @attrs.sort_by(&:first) : @attrs
        attrs.map do |k, v|
          if v == true
            if @options[:format] == :xhtml
              " #{k}=#{@options[:attr_quote]}#{@options[:attr_quote]}"
            else
              " #{k}"
            end
          else
            " #{k}=#{@options[:attr_quote]}#{v}#{@options[:attr_quote]}"
          end
        end.join
      end

      private

      def hyphen_attr(name, escape, value)
        if Hash === value
          value.each do |n, v|
            hyphen_attr("#{name}-#{n}", escape, v)
          end
        else
          attr(name, escape_html(value != true && escape, value))
        end
      end

      def escape_html(escape, value)
        return value unless escape
        @options[:use_html_safe] ? Temple::Utils.escape_html_safe(value) : Temple::Utils.escape_html(value)
      end
    end
  end
end
