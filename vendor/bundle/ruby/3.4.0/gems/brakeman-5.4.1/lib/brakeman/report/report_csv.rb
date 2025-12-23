require 'csv'

class Brakeman::Report::CSV < Brakeman::Report::Base
  def generate_report
    headers = [
      "Confidence",
      "Warning Type",
      "CWE",
      "File",
      "Line",
      "Message",
      "Code",
      "User Input",
      "Check Name",
      "Warning Code",
      "Fingerprint",
      "Link"
    ]

    rows = tracker.filtered_warnings.sort_by do |w|
      [w.confidence, w.warning_type, w.file, w.line || 0, w.fingerprint]
    end.map do |warning|
      generate_row(headers, warning)
    end

    table = CSV::Table.new(rows)

    table.to_csv
  end

  def generate_row headers, warning
    CSV::Row.new headers, warning_row(warning)
  end

  def warning_row warning
    [
      warning.confidence_name,
      warning.warning_type,
      warning.cwe_id.first,
      warning_file(warning),
      warning.line,
      warning.message,
      warning.code && warning.format_code(false),
      warning.user_input && warning.format_user_input(false),
      warning.check_name,
      warning.warning_code,
      warning.fingerprint,
      warning.link,
    ]
  end
end
