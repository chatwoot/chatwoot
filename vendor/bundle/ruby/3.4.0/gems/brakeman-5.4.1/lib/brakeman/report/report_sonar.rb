class Brakeman::Report::Sonar < Brakeman::Report::Base
  def generate_report
    report_object = {
      issues: all_warnings.map { |warning| issue_json(warning) }
    }
    return JSON.pretty_generate report_object
  end
  
  private
  
  def issue_json(warning)
    {
      engineId: "Brakeman",
      ruleId: warning.warning_code,
      type: "VULNERABILITY",
      severity: severity_level_for(warning.confidence),
      primaryLocation: {
        message: warning.message,
        filePath: warning.file.relative,
        textRange: {
          "startLine": warning.line || 1,
          "endLine": warning.line || 1,
        }
      },
      effortMinutes: (4 - warning.confidence) * 15
    }
  end

  def severity_level_for(confidence)
    if confidence == 0
      "CRITICAL"
    elsif confidence == 1
      "MAJOR"
    else
      "MINOR"
    end
  end
end
