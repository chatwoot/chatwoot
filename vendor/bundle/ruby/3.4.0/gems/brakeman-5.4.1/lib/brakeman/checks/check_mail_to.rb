require 'brakeman/checks/base_check'

#Check for cross-site scripting vulnerability in mail_to :encode => :javascript
#with certain versions of Rails (< 2.3.11 or < 3.0.4).
#
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/f02a48ede8315f81
class Brakeman::CheckMailTo < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for mail_to XSS vulnerability in certain versions"

  def run_check
    if (version_between? "2.3.0", "2.3.10" or version_between? "3.0.0", "3.0.3") and result = mail_to_javascript?
      message = msg("Vulnerability in ", msg_code("mail_to"), " using javascript encoding ", msg_cve("CVE-2011-0446"), ". Upgrade to ")

      if version_between? "2.3.0", "2.3.10"
        message << msg_version("2.3.11")
      else
        message << msg_version("3.0.4")
      end

      warn :result => result,
        :warning_type => "Mail Link",
        :warning_code => :CVE_2011_0446,
        :message => message,
        :confidence => :high,
        :gem_info => gemfile_or_environment, # Probably ignored now
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/8CpI7egxX4E/discussion",
        :cwe_id => [79]
    end
  end

  #Check for javascript encoding of mail_to address
  #    mail_to email, name, :encode => :javascript
  def mail_to_javascript?
    Brakeman.debug "Checking calls to mail_to for javascript encoding"

    tracker.find_call(:target => false, :method => :mail_to).each do |result|
      result[:call].each_arg do |arg|
        if hash? arg
          if option = hash_access(arg, :encode)
            return result if symbol? option and option.value == :javascript
          end
        end
      end
    end

    false
  end
end
