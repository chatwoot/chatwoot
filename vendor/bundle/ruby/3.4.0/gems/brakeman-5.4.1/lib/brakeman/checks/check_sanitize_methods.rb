require 'brakeman/checks/base_check'

#sanitize and sanitize_css are vulnerable:
#CVE-2013-1855 and CVE-2013-1857
class Brakeman::CheckSanitizeMethods < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for versions with vulnerable sanitize and sanitize_css"

  def run_check
    @fix_version = case
      when version_between?('2.0.0', '2.3.17')
        '2.3.18'
      when version_between?('3.0.0', '3.0.99')
        '3.2.13'
      when version_between?('3.1.0', '3.1.11')
        '3.1.12'
      when version_between?('3.2.0', '3.2.12')
        '3.2.13'
      end

    if @fix_version
      check_cve_2013_1855
      check_cve_2013_1857
    end

    if tracker.config.has_gem? :'rails-html-sanitizer'
      check_rails_html_sanitizer
    end

    check_cve_2018_8048
  end

  def check_cve_2013_1855
    check_for_cve :sanitize_css, :CVE_2013_1855, "https://groups.google.com/d/msg/rubyonrails-security/4_QHo4BqnN8/_RrdfKk12I4J"
  end

  def check_cve_2013_1857
    check_for_cve :sanitize, :CVE_2013_1857, "https://groups.google.com/d/msg/rubyonrails-security/zAAU7vGTPvI/1vZDWXqBuXgJ"
  end

  def check_for_cve method, code, link
    tracker.find_call(:target => false, :method => method).each do |result|
      next if duplicate? result
      add_result result

      message = msg(msg_version(rails_version), " has a vulnerability in ", msg_code(method), ". Upgrade to ", msg_version(@fix_version), " or patch")

      warn :result => result,
        :warning_type => "Cross-Site Scripting",
        :warning_code => code,
        :message => message,
        :confidence => :high,
        :link_path => link,
        :cwe_id => [79]
    end
  end

  def check_rails_html_sanitizer
    rhs_version = tracker.config.gem_version(:'rails-html-sanitizer')

    if version_between? "1.0.0", "1.0.2", rhs_version
      warn_sanitizer_cve "CVE-2015-7578", "https://groups.google.com/d/msg/rubyonrails-security/uh--W4TDwmI/JbvSRpdbFQAJ", "1.0.3"
      warn_sanitizer_cve "CVE-2015-7580", "https://groups.google.com/d/msg/rubyonrails-security/uh--W4TDwmI/m_CVZtdbFQAJ", "1.0.3"
    end

    if version_between? "1.0.0", "1.0.3", rhs_version
      warn_sanitizer_cve "CVE-2018-3741", "https://groups.google.com/d/msg/rubyonrails-security/tP7W3kLc5u4/uDy2Br7xBgAJ", "1.0.4"
    end
  end

  def check_cve_2018_8048
    if loofah_vulnerable_cve_2018_8048?
      message = msg(msg_version(tracker.config.gem_version(:loofah), "loofah gem"), " is vulnerable (CVE-2018-8048). Upgrade to 2.2.1")

      if tracker.find_call(:target => false, :method => :sanitize).any?
        confidence = :high
      else
        confidence = :medium
      end

      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :CVE_2018_8048,
        :message => message,
        :gem_info => gemfile_or_environment(:loofah),
        :confidence => confidence,
        :link_path => "https://github.com/flavorjones/loofah/issues/144",
        :cwe_id => [79]
    end
  end

  def loofah_vulnerable_cve_2018_8048?
    loofah_version = tracker.config.gem_version(:loofah)

    # 2.2.1 is fix version
    loofah_version and version_between?("0.0.0", "2.2.0", loofah_version)
  end

  def warn_sanitizer_cve cve, link, upgrade_version
    message = msg(msg_version(tracker.config.gem_version(:'rails-html-sanitizer'), "rails-html-sanitizer"), " is vulnerable ", msg_cve(cve), ". Upgrade to ", msg_version(upgrade_version, "rails-html-sanitizer"))

    if tracker.find_call(:target => false, :method => :sanitize).any?
      confidence = :high
    else
      confidence = :medium
    end

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => cve.tr('-', '_').to_sym,
      :message => message,
      :gem_info => gemfile_or_environment(:'rails-html-sanitizer'),
      :confidence => confidence,
      :link_path => link,
      :cwe_id => [79]
  end
end
