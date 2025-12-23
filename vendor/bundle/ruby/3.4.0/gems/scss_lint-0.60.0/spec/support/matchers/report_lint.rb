RSpec::Matchers.define :report_lint do |options|
  options ||= {}
  count = options[:count]
  expected_line = options[:line]

  match do |linter|
    has_lints?(linter, expected_line, count)
  end

  failure_message do |linter|
    expected_count =
      if count.nil?
        'a lint'
      elsif count == 1
        'exactly 1 lint'
      else
        "exactly #{count} lints"
      end

    "expected that #{expected_count} would be reported" +
      (expected_line ? " on line #{expected_line}" : '') +
      case linter.lints.count
      when 0
        ''
      when 1
        ", but one lint was reported on line #{linter.lints.first.location.line}"
      else
        lines = lint_lines(linter)
        ", but lints were reported on lines #{lines[0...-1].join(', ')} and #{lines.last}"
      end
  end

  failure_message_when_negated do
    'expected that a lint would not be reported'
  end

  description do
    'report a lint' + (expected_line ? " on line #{expected_line}" : '')
  end

  def has_lints?(linter, expected_line, count)
    if expected_line && count
      linter.lints.count == count &&
        lint_lines(linter).all? { |line| line == expected_line }
    elsif expected_line
      lint_lines(linter).include?(expected_line)
    elsif count
      linter.lints.count == count
    else
      linter.lints.count > 0
    end
  end

  def lint_lines(linter)
    linter.lints.map { |lint| lint.location.line }
  end
end
