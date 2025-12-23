require 'brakeman/checks/base_check'

class Brakeman::CheckJRubyXML < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions with JRuby XML parsing backend"

  def run_check
    return unless RUBY_PLATFORM == "java"

    fix_version = case
      when version_between?('3.0.0', '3.0.99')
        '3.2.13'
      when version_between?('3.1.0', '3.1.11')
        '3.1.12'
      when version_between?('3.2.0', '3.2.12')
        '3.2.13'
      else
        return
      end

    #Check for workaround
    tracker.find_call(target: :"ActiveSupport::XmlMini", method: :backend=, chained: true).each do |result|
      arg = result[:call].first_arg

      return if string? arg and arg.value == "REXML"
    end

    warn :warning_type => "File Access",
      :warning_code => :CVE_2013_1856,
      :message => msg(msg_version(rails_version), " with JRuby has a vulnerability in XML parser. Upgrade to ", msg_version(fix_version), " or patch"),
      :confidence => :high,
      :gem_info => gemfile_or_environment,
      :link => "https://groups.google.com/d/msg/rubyonrails-security/KZwsQbYsOiI/5kUV7dSCJGwJ",
      :cwe_id => [20]
  end
end
