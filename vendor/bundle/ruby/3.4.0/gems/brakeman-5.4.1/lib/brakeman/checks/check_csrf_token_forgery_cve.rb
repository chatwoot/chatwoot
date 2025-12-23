require 'brakeman/checks/base_check'

class Brakeman::CheckCSRFTokenForgeryCVE < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions with CSRF token forgery vulnerability (CVE-2020-8166)"

  def run_check
    fix_version = case
      when version_between?('0.0.0', '5.2.4.2')
        '5.2.4.3'
      when version_between?('6.0.0', '6.0.3')
        '6.0.3.1'
      else
        nil
      end

    if fix_version
      warn :warning_type => "Cross-Site Request Forgery",
        :warning_code => :CVE_2020_8166,
        :message => msg(msg_version(rails_version), " has a vulnerability that may allow CSRF token forgery. Upgrade to ", msg_version(fix_version), " or patch"),
        :confidence => :medium,
        :gem_info => gemfile_or_environment,
        :link => "https://groups.google.com/g/rubyonrails-security/c/NOjKiGeXUgw",
        :cwe_id => [352]
    end
  end
end

