require 'brakeman/checks/base_check'

#Check for uses of strip_tags in Rails versions before 3.0.17, 3.1.8, 3.2.8 (including 2.3.x):
#https://groups.google.com/d/topic/rubyonrails-security/FgVEtBajcTY/discussion
#
#Check for uses of strip_tags in Rails versions before 2.3.13 and 3.0.10:
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b9130749b74ea12
#
#Check for user of strip_tags with rails-html-sanitizer 1.0.2:
#https://groups.google.com/d/msg/rubyonrails-security/OU9ugTZcbjc/PjEP46pbFQAJ
class Brakeman::CheckStripTags < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report strip_tags vulnerabilities"

  def run_check
    if uses_strip_tags?
      cve_2011_2931
      cve_2012_3465
    end

    cve_2015_7579
  end

  def cve_2011_2931
    if version_between?('2.0.0', '2.3.12') or version_between?('3.0.0', '3.0.9')
      if rails_version =~ /^3/
        message = msg("Versions before 3.0.10 have a vulnerability in ", msg_code("strip_tags"), " ", msg_cve("CVE-2011-2931"))
      else
        message = msg("Versions before 2.3.13 have a vulnerability in ", msg_code("strip_tags"), " ", msg_cve("CVE-2011-2931"))
      end

      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :CVE_2011_2931,
        :message => message,
        :gem_info => gemfile_or_environment,
        :confidence => :high,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/K5EwdJt06hI/discussion",
        :cwe_id => [79]
    end
  end

  def cve_2012_3465
    message = msg(msg_version(rails_version), " has a vulnerability in ", msg_code("strip_tags"), " ", msg_cve("CVE-2012-3465"), ". Upgrade to ")

    case
    when (version_between?('2.0.0', '2.3.14') and tracker.config.escape_html?)
      message = msg("All Rails 2.x versions have a vulnerability in ", msg_code("strip_tags"), " ", msg_cve("CVE-2012-3465"))
    when version_between?('3.0.10', '3.0.16')
      message << msg_version('3.0.17')
    when version_between?('3.1.0', '3.1.7')
      message << msg_version('3.1.8')
    when version_between?('3.2.0', '3.2.7')
      message << msg_version('3.2.8')
    else
      return
    end

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2012_3465,
      :message => message,
      :confidence => :high,
      :gem_info => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/topic/rubyonrails-security/FgVEtBajcTY/discussion",
      :cwe_id => [79]
  end

  def cve_2015_7579
    if tracker.config.gem_version(:'rails-html-sanitizer') == '1.0.2'
      if uses_strip_tags?
        confidence = :high
      else
        confidence = :medium
      end

      message = msg(msg_version("1.0.2", "rails-html-sanitizer"), " is vulnerable (CVE-2015-7579). Upgrade to ", msg_version("1.0.3", "rails-html-sanitizer"))

      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :CVE_2015_7579,
        :message => message,
        :confidence => confidence,
        :gem_info => gemfile_or_environment(:"rails-html-sanitizer"),
        :link_path => "https://groups.google.com/d/msg/rubyonrails-security/OU9ugTZcbjc/PjEP46pbFQAJ",
        :cwe_id => [79]

    end
  end

  def uses_strip_tags?
    Brakeman.debug "Finding calls to strip_tags()"

    not tracker.find_call(:target => false, :method => :strip_tags, :nested => true).empty?
  end
end
