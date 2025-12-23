require 'brakeman/checks/base_check'

class Brakeman::CheckPageCachingCVE < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for page caching vulnerability (CVE-2020-8159)"

  def run_check
    gem_name = 'actionpack-page_caching'
    gem_version = tracker.config.gem_version(gem_name.to_sym)
    upgrade_version = '1.2.2'
    cve = 'CVE-2020-8159'

    return unless gem_version and version_between?('0.0.0', '1.2.1', gem_version)

    message = msg("Directory traversal vulnerability in ", msg_version(gem_version, gem_name), " ", msg_cve(cve), ". Upgrade to ", msg_version(upgrade_version, gem_name))

    if uses_caches_page?
      confidence = :high
    else
      confidence = :weak
    end

    warn :warning_type => 'Directory Traversal',
      :warning_code => :CVE_2020_8159,
      :message => message,
      :confidence => confidence,
      :link_path => 'https://groups.google.com/d/msg/rubyonrails-security/CFRVkEytdP8/c5gmICECAgAJ',
      :gem_info => gemfile_or_environment(gem_name),
      :cwe_id => [22]
  end

  def uses_caches_page?
    tracker.controllers.any? do |name, controller|
      controller.options.has_key? :caches_page
    end
  end
end
