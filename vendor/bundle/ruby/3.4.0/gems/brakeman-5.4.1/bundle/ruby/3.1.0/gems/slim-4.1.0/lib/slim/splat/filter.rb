module Slim
  module Splat
    # @api private
    class Filter < ::Slim::Filter
      define_options :merge_attrs, :attr_quote, :sort_attrs, :default_tag, :format, :disable_capture,
                     hyphen_attrs: %w(data aria), use_html_safe: ''.respond_to?(:html_safe?)

      def call(exp)
        @splat_options = nil
        exp = compile(exp)
        if @splat_options
          opts = options.to_hash.reject {|k,v| !Filter.options.valid_key?(k) }.inspect
          [:multi, [:code, "#{@splat_options} = #{opts}"], exp]
        else
          exp
        end
      end

      # Handle tag expression `[:html, :tag, name, attrs, content]`
      #
      # @param [String] name Tag name
      # @param [Array] attrs Temple expression
      # @param [Array] content Temple expression
      # @return [Array] Compiled temple expression
      def on_html_tag(name, attrs, content = nil)
        return super if name != '*'
        builder, block = make_builder(attrs[2..-1])
        if content
          [:multi,
           block,
           [:slim, :output, false,
            "#{builder}.build_tag #{empty_exp?(content) ? '{}' : 'do'}",
            compile(content)]]
        else
          [:multi,
           block,
           [:dynamic, "#{builder}.build_tag"]]
        end
      end

      # Handle attributes expression `[:html, :attrs, *attrs]`
      #
      # @param [Array] attrs Array of temple expressions
      # @return [Array] Compiled temple expression
      def on_html_attrs(*attrs)
        if attrs.any? {|attr| splat?(attr) }
          builder, block = make_builder(attrs)
          [:multi,
           block,
           [:dynamic, "#{builder}.build_attrs"]]
        else
          super
        end
      end

      protected

      def splat?(attr)
        # Splat attribute given
        attr[0] == :slim && attr[1] == :splat ||
          # Hyphenated attribute also needs splat handling
          (attr[0] == :html && attr[1] == :attr && options[:hyphen_attrs].include?(attr[2]) &&
           attr[3][0] == :slim && attr[3][1] == :attrvalue)
      end

      def make_builder(attrs)
        @splat_options ||= unique_name
        builder = unique_name
        result = [:multi, [:code, "#{builder} = ::Slim::Splat::Builder.new(#{@splat_options})"]]
        attrs.each do |attr|
          result <<
            if attr[0] == :html && attr[1] == :attr
              if attr[3][0] == :slim && attr[3][1] == :attrvalue
                [:code, "#{builder}.code_attr(#{attr[2].inspect}, #{attr[3][2]}, (#{attr[3][3]}))"]
              else
                tmp = unique_name
                [:multi,
                 [:capture, tmp, compile(attr[3])],
                 [:code, "#{builder}.attr(#{attr[2].inspect}, #{tmp})"]]
              end
            elsif attr[0] == :slim && attr[1] == :splat
              [:code, "#{builder}.splat_attrs((#{attr[2]}))"]
            else
              attr
            end
        end
        return builder, result
      end
    end
  end
end
