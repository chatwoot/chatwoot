# frozen_string_literal: true

require 'erubi'

module Erubi
  # An engine class that supports capturing blocks via the <tt><%=</tt> and <tt><%==</tt> tags:
  #
  #   <%= upcase_form do %>
  #     <%= 'foo' %>
  #   <% end %>
  #
  # Where +upcase_form+ is defined like:
  #
  #   def upcase_form(&block)
  #     "<form>#{@bufvar.capture(&block).upcase}</form>"
  #   end
  #
  # With output being:
  #
  #   <form>
  #     FOO
  #   </form>
  #
  # This requires using a string subclass as the buffer value, provided by the
  # CaptureBlockEngine::Buffer class.
  #
  # This engine does not support the :escapefunc option.  To change the escaping function,
  # use a subclass of CaptureBlockEngine::Buffer and override the #| method.
  #
  # This engine does not support the :chain_appends option, and ignores it if present.
  class CaptureBlockEngine < Engine
    class Buffer < ::String
    
      # Convert argument to string when concatening
      def <<(v)
        concat(v.to_s)
      end

      # Escape argument using Erubi.h then then concatenate it to the receiver.
      def |(v)
        concat(h(v))
      end

      # Temporarily clear the receiver before yielding to the block, yield the
      # given args to the block, return any data captured by the receiver, and
      # restore the original data the receiver contained before returning.
      def capture(*args)
        prev = dup
        replace("") # 1.8 support!
        yield(*args)
        dup
      ensure
        replace(prev)
      end

      private

      if RUBY_VERSION >= '2'
        define_method(:h, ::Erubi.instance_method(:h))
      # :nocov:
      else
        def h(v)
          ::Erubi.h(v)
        end
      end
      # :nocov:
    end

    def initialize(input, properties={})
      properties = Hash[properties]
      properties[:bufval] ||= '::Erubi::CaptureBlockEngine::Buffer.new'
      properties[:chain_appends] = false
      super
    end

    private

    def add_expression_result(code)
      add_expression_op(' <<= ', code)
    end

    def add_expression_result_escaped(code)
      add_expression_op(' |= ', code)
    end

    def add_expression_op(op, code)
      check = /\A\s*\z/.send(MATCH_METHOD, code) ? "''" : ''
      with_buffer{@src << op  << check << code}
    end
  end
end
