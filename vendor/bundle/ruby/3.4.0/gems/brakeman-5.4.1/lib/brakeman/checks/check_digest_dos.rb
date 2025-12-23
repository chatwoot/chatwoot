require 'brakeman/checks/base_check'

class Brakeman::CheckDigestDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for digest authentication DoS vulnerability"

  def run_check
    message = msg("Vulnerability in digest authentication ", msg_cve("CVE-2012-3424"), ". Upgrade to ")

    if version_between? "3.0.0", "3.0.15"
      message << msg_version("3.0.16")
    elsif version_between? "3.1.0", "3.1.6"
      message << msg_version("3.1.7")
    elsif version_between? "3.2.0", "3.2.5"
      message << msg_version("3.2.7")
    else
      return
    end

    if with_http_digest?
      confidence = :high
    else
      confidence = :weak
    end

    warn :warning_type => "Denial of Service",
      :warning_code => :CVE_2012_3424,
      :message => message,
      :confidence => confidence,
      :link_path => "https://groups.google.com/d/topic/rubyonrails-security/vxJjrc15qYM/discussion",
      :gem_info => gemfile_or_environment,
      :cwe_id => [287]
  end

  def with_http_digest?
    not tracker.find_call(:target => false, :method => [:authenticate_or_request_with_http_digest, :authenticate_with_http_digest]).empty?
  end
end
