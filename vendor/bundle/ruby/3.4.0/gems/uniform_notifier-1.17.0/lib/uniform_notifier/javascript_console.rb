# frozen_string_literal: true

class UniformNotifier
  class JavascriptConsole < Base
    class << self
      def active?
        !!UniformNotifier.console
      end

      protected

      def _inline_notify(data)
        message = data.values.compact.join("\n")
        options = UniformNotifier.console.is_a?(Hash) ? UniformNotifier.console : {}
        script_attributes = options[:attributes] || {}

        code = <<~CODE
          if (typeof(console) !== 'undefined' && console.log) {
            if (console.groupCollapsed && console.groupEnd) {
              console.groupCollapsed(#{'Uniform Notifier'.inspect});
              console.log(#{message.inspect});
              console.groupEnd();
            } else {
              console.log(#{message.inspect});
            }
          }
        CODE

        wrap_js_association code, script_attributes
      end
    end
  end
end
