require 'brakeman/checks/base_check'

#Check for unsafe manipulation of strings
#Right now this is just a version check for
#https://groups.google.com/group/rubyonrails-security/browse_thread/thread/edd28f1e3d04e913?pli=1
class Brakeman::CheckSafeBufferManipulation < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for Rails versions with SafeBuffer bug"

  def run_check

    if version_between? "3.0.0", "3.0.11"
      suggested_version = "3.0.12"
    elsif version_between? "3.1.0", "3.1.3"
      suggested_version = "3.1.4"
    elsif version_between? "3.2.0", "3.2.1"
      suggested_version = "3.2.2"
    else
      return
    end

    message = msg(msg_version(rails_version), " has a vulnerability in ", msg_code("SafeBuffer"), ". Upgrade to ", msg_version(suggested_version), " or apply patches")

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => :safe_buffer_vuln, 
      :message => message,
      :confidence => :medium,
      :gem_info => gemfile_or_environment,
      :cwe_id => [79]
  end
end
