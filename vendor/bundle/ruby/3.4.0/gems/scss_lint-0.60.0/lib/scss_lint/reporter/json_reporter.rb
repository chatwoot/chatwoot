require 'json'

module SCSSLint
  # Reports lints in a JSON format.
  class Reporter::JSONReporter < Reporter
    def report_lints
      output = {}
      lints.group_by(&:filename).each do |filename, file_lints|
        output[filename] = file_lints.map do |lint|
          issue_hash(lint)
        end
      end
      JSON.pretty_generate(output)
    end

  private

    def issue_hash(lint)
      {
        'line' => lint.location.line,
        'column' => lint.location.column,
        'length' => lint.location.length,
        'severity' => lint.severity,
        'reason' => lint.description,
      }.tap do |hash|
        hash['linter'] = lint.linter.name
      end
    end
  end
end
