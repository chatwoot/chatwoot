require "json"
require "yaml"
require "pathname"

class Brakeman::Report::CodeClimate < Brakeman::Report::Base
  DOCUMENTATION_PATH = File.expand_path("../../../../docs/warning_types", __FILE__)
  REMEDIATION_POINTS_CONFIG_PATH = File.expand_path("../config/remediation.yml", __FILE__)
  REMEDIATION_POINTS_DEFAULT = 300_000

  def generate_report
    all_warnings.map { |warning| issue_json(warning) }.join("\0")
  end

  private

  def issue_json(warning)
    warning_code_name = name_for(warning.warning_code)

    {
      type: "Issue",
      check_name: warning_code_name,
      description: warning.message,
      fingerprint: warning.fingerprint,
      categories: ["Security"],
      severity: severity_level_for(warning.confidence),
      remediation_points: remediation_points_for(warning_code_name),
      location: {
        path: file_path(warning),
        lines: {
          begin: warning.line || 1,
          end: warning.line || 1,
        }
      },
      content: {
        body: content_for(warning.warning_code, warning.link)
      }
    }.to_json
  end

  def severity_level_for(confidence)
    if confidence == 0
      "critical"
    else
      "normal"
    end
  end

  def remediation_points_for(warning_code)
    @remediation_points ||= YAML.load_file(REMEDIATION_POINTS_CONFIG_PATH)
    @remediation_points.fetch(name_for(warning_code), REMEDIATION_POINTS_DEFAULT)
  end

  def name_for(warning_code)
    @warning_codes ||= Brakeman::WarningCodes::Codes.invert
    @warning_codes[warning_code].to_s
  end

  def content_for(warning_code, link)
    @contents ||= {}
    unless link.nil?
      @contents[warning_code] ||= local_content_for(link) || "Read more: #{link}"
    end
  end

  def local_content_for(link)
    directory = link.split("/").last
    filename = File.join(DOCUMENTATION_PATH, directory, "index.markdown")

    File.read(filename) if File.exist?(filename)
  end

  def file_path(warning)
    if tracker.options[:path_prefix]
      (Pathname.new(tracker.options[:path_prefix]) + Pathname.new(warning.file.relative)).to_s
    else
      warning.relative_path
    end
  end
end
