class Brakeman::CheckSprocketsPathTraversal < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for CVE-2018-3760"

  def run_check
    sprockets_version = tracker.config.gem_version(:sprockets)

    return unless sprockets_version
    return if has_workaround?

    case
    when version_between?("0.0.0", "2.12.4", sprockets_version)
      upgrade_version = "2.12.5"
      confidence = :weak
    when version_between?("3.0.0", "3.7.1", sprockets_version)
      upgrade_version = "3.7.2"
      confidence = :high
    when version_between?("4.0.0.beta1", "4.0.0.beta7", sprockets_version)
      upgrade_version = "4.0.0.beta8"
      confidence = :high
    else
      return
    end

    message = msg(msg_version(sprockets_version, "sprockets"), " has a path traversal vulnerability ", msg_cve("CVE-2018-3760"), ". Upgrade to ", msg_version(upgrade_version, "sprockets"), " or newer")

    warn :warning_type => "Path Traversal",
      :warning_code => :CVE_2018_3760,
      :message => message,
      :confidence => confidence,
      :gem_info => gemfile_or_environment(:sprockets),
      :link_path => "https://groups.google.com/d/msg/rubyonrails-security/ft_J--l55fM/7roDfQ50BwAJ",
      :cwe_id => [22, 200]
  end

  def has_workaround?
    false? (tracker.config.rails[:assets] and tracker.config.rails[:assets][:compile])
  end
end
