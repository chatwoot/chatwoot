# frozen_string_literal: true

class UniformNotifier
  class Base
    class << self
      def active?
        false
      end

      def inline_notify(data)
        return unless active?

        # For compatibility to the old protocol
        data = { title: data } if data.is_a?(String)

        _inline_notify(data)
      end

      def out_of_channel_notify(data)
        return unless active?

        # For compatibility to the old protocol
        data = { title: data } if data.is_a?(String)

        _out_of_channel_notify(data)
      end

      protected

      def _inline_notify(data); end

      def _out_of_channel_notify(data); end

      def wrap_js_association(code, attributes = {})
        attributes = { type: 'text/javascript' }.merge(attributes || {})
        attributes_string = attributes.map { |k, v| "#{k}=#{v.to_s.inspect}" }
                                      .join(' ')

        <<~CODE
          <script #{attributes_string}>/*<![CDATA[*/
          #{code}
          /*]]>*/</script>
        CODE
      end
    end
  end
end
