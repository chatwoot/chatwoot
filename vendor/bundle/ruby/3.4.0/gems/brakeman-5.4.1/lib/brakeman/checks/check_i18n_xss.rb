require 'brakeman/checks/base_check'

class Brakeman::CheckI18nXSS < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for i18n XSS (CVE-2013-4491)"

  def run_check
    if (version_between? "3.0.6", "3.2.15" or version_between? "4.0.0", "4.0.1") and not has_workaround?
      i18n_gem = tracker.config.gem_version :i18n
      message = msg(msg_version(rails_version), " has an XSS vulnerability in ", msg_version(i18n_gem, "i18n"), " ", msg_cve("CVE-2013-4491"), ". Upgrade to ")

      if version_between? "3.0.6", "3.1.99" and version_before i18n_gem, "0.5.1"
        message << msg_version("3.2.16 or i18n 0.5.1")
      elsif version_between? "3.2.0", "4.0.1" and version_before i18n_gem, "0.6.6"
        message << msg_version("4.0.2 or i18n 0.6.6")
      else
        return
      end

      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :CVE_2013_4491,
        :message => message,
        :confidence => :medium,
        :gem_info => gemfile_or_environment(:i18n),
        :link_path => "https://groups.google.com/d/msg/ruby-security-ann/pLrh6DUw998/bLFEyIO4k_EJ",
        :cwe_id => [79]
    end
  end

  def version_before gem_version, target
    return true unless gem_version
    gem_version.split('.').map(&:to_i).zip(target.split('.').map(&:to_i)).each do |gv, t|
      if gv < t
        return true
      elsif gv > t
        return false
      end
    end

    false
  end

  def has_workaround?
    tracker.find_call(target: :I18n, method: :const_defined?, chained: true).any? do |match|
      match[:call].first_arg == s(:lit, :MissingTranslation)
    end
  end
end
