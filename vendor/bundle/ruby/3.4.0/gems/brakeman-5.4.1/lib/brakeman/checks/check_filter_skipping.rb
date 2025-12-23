require 'brakeman/checks/base_check'

#Check for filter skipping vulnerability
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/3420ac71aed312d6
class Brakeman::CheckFilterSkipping < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions 3.0-3.0.9 which had a vulnerability in filters"

  def run_check
    if version_between?('3.0.0', '3.0.9') and uses_arbitrary_actions?

      warn :warning_type => "Default Routes",
        :warning_code => :CVE_2011_2929,
        :message => msg("Rails versions before 3.0.10 have a vulnerability which allows filters to be bypassed", msg_cve("CVE-2011-2929")),
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/NCCsca7TEtY/discussion",
        :cwe_id => [20]
    end
  end

  def uses_arbitrary_actions?
    tracker.routes.each do |_name, actions|
      if actions.include? :allow_all_actions
        return true
      end
    end

    false
  end
end
