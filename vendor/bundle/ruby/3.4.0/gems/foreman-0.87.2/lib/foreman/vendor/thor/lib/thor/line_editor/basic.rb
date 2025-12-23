class Foreman::Thor
  module LineEditor
    class Basic
      attr_reader :prompt, :options

      def self.available?
        true
      end

      def initialize(prompt, options)
        @prompt = prompt
        @options = options
      end

      def readline
        $stdout.print(prompt)
        get_input
      end

    private

      def get_input
        if echo?
          $stdin.gets
        else
          $stdin.noecho(&:gets)
        end
      end

      def echo?
        options.fetch(:echo, true)
      end
    end
  end
end
