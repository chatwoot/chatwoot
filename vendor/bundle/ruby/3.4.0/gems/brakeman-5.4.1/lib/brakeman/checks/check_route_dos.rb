require 'brakeman/checks/base_check'

class Brakeman::CheckRouteDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for route DoS (CVE-2015-7581)"

  def run_check
    fix_version = case
                  when version_between?("4.0.0", "4.1.14")
                    "4.1.14.1"
                  when version_between?("4.2.0", "4.2.5")
                    "4.2.5.1"
                  else
                    return
                  end

    if controller_wildcards?
      message = msg(msg_version(rails_version), " has a denial of service vulnerability with ", msg_code(":controller"), " routes ", msg_cve("CVE-2015-7581"), ". Upgrade to ", msg_version(fix_version))

      warn :warning_type => "Denial of Service",
        :warning_code => :CVE_2015_7581,
        :message => message,
        :confidence => :medium,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/msg/rubyonrails-security/dthJ5wL69JE/YzPnFelbFQAJ",
        :cwe_id => [399]
    end
  end

  def controller_wildcards?
    tracker.routes.each do |name, actions|
      if name == :':controllerController'
        # awful hack for routes with :controller in them
        return true
      elsif string? actions and actions.value.include? ":controller"
        return true
      end
    end

    false
  end
end
