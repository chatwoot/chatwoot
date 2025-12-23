require 'brakeman/checks/base_check'

#Check for versions with vulnerable html escape method
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/56bffb5923ab1195
class Brakeman::CheckEscapeFunction < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions before 2.3.14 which have a vulnerable escape method"

  def run_check
    if version_between?('2.0.0', '2.3.13') and RUBY_VERSION < '1.9.0' 

      warn :warning_type => 'Cross-Site Scripting',
        :warning_code => :CVE_2011_2932,
        :message => msg("Rails versions before 2.3.14 have a vulnerability in the ", msg_code("escape"), " method when used with Ruby 1.8 ", msg_cve("CVE-2011-2932")),
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/Vr_7WSOrEZU/discussion",
        :cwe_id => [79]
    end
  end
end
