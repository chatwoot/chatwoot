require 'brakeman/checks/base_check'

class Brakeman::CheckYAMLParsing < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for YAML parsing vulnerabilities (CVE-2013-0156)"

  def run_check
    return unless version_between? "0.0.0", "2.3.14" or
                  version_between? "3.0.0", "3.0.18" or
                  version_between? "3.1.0", "3.1.9" or
                  version_between? "3.2.0", "3.2.10"

    unless disabled_xml_parser? or disabled_xml_dangerous_types?
      new_version = if version_between? "0.0.0", "2.3.14"
                      "2.3.15"
                    elsif version_between? "3.0.0", "3.0.18"
                      "3.0.19"
                    elsif version_between? "3.1.0", "3.1.9"
                      "3.1.10"
                    elsif version_between? "3.2.0", "3.2.10"
                      "3.2.11"
                    end

      message = msg(msg_version(rails_version), " has a remote code execution vulnerability. Upgrade to ", msg_version(new_version), " or disable XML parsing")

      warn :warning_type => "Remote Code Execution",
        :warning_code => :CVE_2013_0156,
        :message => message,
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/61bkgvnSGTQ/discussion",
        :cwe_id => [20]
    end

    #Warn if app accepts YAML
    if version_between?("0.0.0", "2.3.14") and enabled_yaml_parser?
      message = "Parsing YAML request parameters enables remote code execution: disable YAML parser"

      warn :warning_type => "Remote Code Execution",
        :warning_code => :CVE_2013_0156,
        :message => message,
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/61bkgvnSGTQ/discussion",
        :cwe_id => [20]
    end
  end

  def disabled_xml_parser?
    if version_between? "0.0.0", "2.3.14"
      #Look for ActionController::Base.param_parsers.delete(Mime::XML)
      matches = tracker.find_call(target: :"ActionController::Base.param_parsers", method: :delete)
    else
      #Look for ActionDispatch::ParamsParser::DEFAULT_PARSERS.delete(Mime::XML)
      matches = tracker.find_call(target: :"ActionDispatch::ParamsParser::DEFAULT_PARSERS", method: :delete)
    end

    unless matches.empty?
      mime_xml = s(:colon2, s(:const, :Mime), :XML)

      matches.each do |result|
        if result[:call].first_arg == mime_xml
          return true
        end
      end
    end

    false
  end

  #Look for ActionController::Base.param_parsers[Mime::YAML] = :yaml
  #in Rails 2.x apps
  def enabled_yaml_parser?
    matches = tracker.find_call(target: :'ActionController::Base.param_parsers', method: :[]=)

    mime_yaml = s(:colon2, s(:const, :Mime), :YAML)

    matches.each do |result|
      if result[:call].first_arg == mime_yaml and
        symbol? result[:call].second_arg and
        result[:call].second_arg.value == :yaml

        return true
      end
    end

    false
  end

  def disabled_xml_dangerous_types?
    if version_between? "0.0.0", "2.3.14"
      matches = tracker.find_call(target: :"ActiveSupport::CoreExtensions::Hash::Conversions::XML_PARSING", method: :delete)
    else
      matches = tracker.find_call(target: :"ActiveSupport::XmlMini::PARSING", method: :delete)
    end

    symbols_off = false
    yaml_off = false

    matches.each do |result|
      arg = result[:call].first_arg

      if string? arg
        if arg.value == "yaml"
          yaml_off = true
        elsif arg.value == "symbol"
          symbols_off = true
        end
      end
    end

    symbols_off and yaml_off
  end
end
