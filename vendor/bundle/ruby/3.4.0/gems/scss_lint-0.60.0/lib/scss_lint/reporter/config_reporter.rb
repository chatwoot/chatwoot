module SCSSLint
  # Returns a YAML configuration where all linters are disabled which
  # caused a lint.
  class Reporter::ConfigReporter < Reporter
    def report_lints
      { 'linters' => disabled_linters }.to_yaml unless lints.empty?
    end

  private

    def disabled_linters
      linters.each_with_object({}) do |linter, m|
        m[linter] = { 'enabled' => false }
      end
    end

    def linters
      lints.map { |lint| linter_name(lint.linter) }.compact.uniq.sort
    end

    def linter_name(linter)
      linter.class.to_s.split('::').last
    end
  end
end
