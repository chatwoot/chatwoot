require 'brakeman/checks/base_check'

class Brakeman::CheckBasicAuthTimingAttack < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for timing attack in basic auth (CVE-2015-7576)"

  def run_check
    @upgrade = case
               when version_between?("0.0.0", "3.2.22")
                 "3.2.22.1"
               when version_between?("4.0.0", "4.1.14")
                 "4.1.14.1"
               when version_between?("4.2.0", "4.2.5")
                 "4.2.5.1"
               else
                 return
               end

    check_basic_auth_call
  end

  def check_basic_auth_call
    tracker.find_call(target: nil, method: :http_basic_authenticate_with).each do |result|
      warn :result => result,
        :warning_type => "Timing Attack",
        :warning_code => :CVE_2015_7576,
        :message => msg("Basic authentication in ", msg_version(rails_version), " is vulnerable to timing attacks. Upgrade to ", msg_version(@upgrade)),
        :confidence => :high,
        :link => "https://groups.google.com/d/msg/rubyonrails-security/ANv0HDHEC3k/mt7wNGxbFQAJ",
        :cwe_id => [1254]
    end
  end
end
