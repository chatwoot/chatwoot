module SCSSLint
  class NoSuchLinter < StandardError; end

  # Stores all linters available to the application.
  module LinterRegistry
    @linters = []

    class << self
      attr_reader :linters

      def included(base)
        @linters << base
      end

      def extract_linters_from(linter_names)
        linter_names.map do |linter_name|
          begin
            Linter.const_get(linter_name)
          rescue NameError
            raise NoSuchLinter, "Linter #{linter_name} does not exist"
          end
        end
      end
    end
  end
end
