module Slim
  module Smart
    # Perform smart entity escaping in the
    # expressions `[:slim, :text, type, Expression]`.
    #
    # @api private
    class Escaper < ::Slim::Filter
      define_options smart_text_escaping: true

      def call(exp)
        if options[:smart_text_escaping]
          super
        else
          exp
        end
      end

      def on_slim_text(type, content)
        [:escape, type != :verbatim, [:slim, :text, type, compile(content)]]
      end

      def on_static(string)
        # Prevent obvious &foo; and &#1234; and &#x00ff; entities from escaping.
        block = [:multi]
        until string.empty?
          case string
          when /\A&([a-z][a-z0-9]*|#x[0-9a-f]+|#\d+);/i
            # Entity.
            block << [:escape, false, [:static, $&]]
            string = $'
          when /\A&?[^&]*/
            # Other text.
            block << [:static, $&]
            string = $'
          end
        end
        block
      end

    end
  end
end
