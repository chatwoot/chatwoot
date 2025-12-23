require 'brakeman/checks/base_check'

class Brakeman::CheckMimeTypeDoS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for mime type denial of service (CVE-2016-0751)"

  def run_check
    fix_version = case
               when version_between?("3.0.0", "3.2.22")
                 "3.2.22.1"
               when version_between?("4.0.0", "4.1.14")
                 "4.1.14.1"
               when version_between?("4.2.0", "4.2.5")
                 "4.2.5.1"
               else
                 return
               end

    return if has_workaround?

    message = msg(msg_version(rails_version), " is vulnerable to denial of service via mime type caching ", msg_cve("CVE-2016-0751"), ". Upgrade to ", msg_version(fix_version))

    warn :warning_type => "Denial of Service",
      :warning_code => :CVE_2016_0751,
      :message => message,
      :confidence => :medium,
      :gem_info => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/msg/rubyonrails-security/9oLY_FCzvoc/w9oI9XxbFQAJ",
      :cwe_id => [399]
  end

  def has_workaround?
    tracker.find_call(target: :Mime, method: :const_set).any? do |match|
      arg = match[:call].first_arg

      symbol? arg and arg.value == :LOOKUP
    end
  end
end
