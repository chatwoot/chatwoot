require "set"

module SafeYAML
  class LibyamlChecker
    LIBYAML_VERSION = Psych::LIBYAML_VERSION rescue nil

    # Do proper version comparison (e.g. so 0.1.10 is >= 0.1.6)
    SAFE_LIBYAML_VERSION = Gem::Version.new("0.1.6")

    KNOWN_PATCHED_LIBYAML_VERSIONS = Set.new([
      # http://people.canonical.com/~ubuntu-security/cve/2014/CVE-2014-2525.html
      "0.1.4-2ubuntu0.12.04.3",
      "0.1.4-2ubuntu0.12.10.3",
      "0.1.4-2ubuntu0.13.10.3",
      "0.1.4-3ubuntu3",

      # https://security-tracker.debian.org/tracker/CVE-2014-2525
      "0.1.3-1+deb6u4",
      "0.1.4-2+deb7u4",
      "0.1.4-3.2"
    ]).freeze

    def self.libyaml_version_ok?
      return true if YAML_ENGINE != "psych" || defined?(JRUBY_VERSION)
      return true if Gem::Version.new(LIBYAML_VERSION || "0") >= SAFE_LIBYAML_VERSION
      return libyaml_patched?
    end

    def self.libyaml_patched?
      return false if (`which dpkg` rescue '').empty?
      libyaml_version = `dpkg -s libyaml-0-2`.match(/^Version: (.*)$/)
      return false if libyaml_version.nil?
      KNOWN_PATCHED_LIBYAML_VERSIONS.include?(libyaml_version[1])
    end
  end
end
