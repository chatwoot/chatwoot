module RSpec
  module Core
    # @private
    # Wrapper around Ruby's `DidYouMean::SpellChecker` when available to provide file name suggestions.
    class DidYouMean
      attr_reader :relative_file_name

      def initialize(relative_file_name)
        @relative_file_name = relative_file_name
      end

      if defined?(::DidYouMean::SpellChecker)
        # provide probable suggestions
        def call
          checker = ::DidYouMean::SpellChecker.new(:dictionary => Dir["spec/**/*.rb"])
          probables = checker.correct(relative_file_name.sub('./', ''))[0..2]
          return '' unless probables.any?

          formats probables
        end
      else
        # return a hint if API for ::DidYouMean::SpellChecker not supported
        def call
          "\nHint: Install the `did_you_mean` gem in order to provide suggestions for similarly named files."
        end
      end

      private

      def formats(probables)
        rspec_format = probables.map { |s, _| "rspec ./#{s}" }
        red_font(top_and_tail rspec_format)
      end

      def top_and_tail(rspec_format)
        spaces = ' ' * 20
        rspec_format.insert(0, ' - Did you mean?').join("\n#{spaces}") + "\n"
      end

      def red_font(mytext)
        colorizer = ::RSpec::Core::Formatters::ConsoleCodes
        colorizer.wrap mytext, :failure
      end
    end
  end
end
