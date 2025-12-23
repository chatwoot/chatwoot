# frozen_string_literal: true

class UniformNotifier
  class TerminalNotifier < Base
    class << self
      def active?
        !!UniformNotifier.terminal_notifier
      end

      protected

      def _out_of_channel_notify(data)
        unless defined?(::TerminalNotifier)
          begin
            require 'terminal-notifier'
          rescue LoadError
            raise NotificationError,
                  'You must install the terminal-notifier gem to use terminal_notifier: `gem install terminal-notifier`'
          end
        end

        ::TerminalNotifier.notify(data[:body], title: data[:title])
      end
    end
  end
end
