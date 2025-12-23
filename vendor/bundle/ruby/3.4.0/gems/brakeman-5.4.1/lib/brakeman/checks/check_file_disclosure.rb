require 'brakeman/checks/base_check'

class Brakeman::CheckFileDisclosure < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = 'Checks for versions with file existence disclosure vulnerability'

  def run_check
    fix_version = case
      when version_between?('2.0.0', '2.3.18')
        '3.2.21'
      when version_between?('3.0.0', '3.2.20')
        '3.2.21'
      when version_between?('4.0.0', '4.0.11')
        '4.0.12'
      when version_between?('4.1.0', '4.1.7')
        '4.1.8'
      else
        nil
      end

    if fix_version and serves_static_assets?
      warn :warning_type => "File Access",
        :warning_code => :CVE_2014_7829,
        :message => msg(msg_version(rails_version), " has a file existence disclosure vulnerability. Upgrade to ", msg_version(fix_version), " or disable serving static assets"),
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/msg/rubyonrails-security/23fiuwb1NBA/MQVM1-5GkPMJ",
        :cwe_id => [22]
    end
  end

  def serves_static_assets?
    true? tracker.config.rails[:serve_static_assets]
  end
end
