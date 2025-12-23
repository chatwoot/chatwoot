require 'brakeman/checks/base_check'

#Warn about response splitting in Rails versions before 2.3.13
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/6ffc93bde0298768
class Brakeman::CheckResponseSplitting < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report response splitting in Rails 2.3.0 - 2.3.13"

  def run_check
    if version_between?('2.3.0', '2.3.13')

      warn :warning_type => "Response Splitting",
        :warning_code => :CVE_2011_3186,
        :message => msg("Rails versions before 2.3.14 have a vulnerability content type handling allowing injection of headers ", msg_cve("CVE-2011-3186")),
        :confidence => :medium,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/b_yTveAph2g/discussion",
        :cwe_id => [94]
    end
  end
end
