module VersionGem
  # Helpers for library CI integration against many different versions of Ruby
  module Ruby
    RUBY_VER = ::Gem::Version.new(RUBY_VERSION)

    def gte_minimum_version?(version, engine = "ruby")
      RUBY_VER >= ::Gem::Version.new(version) && ::RUBY_ENGINE == engine
    end
    module_function :gte_minimum_version?

    def actual_minor_version?(major, minor, engine = "ruby")
      major.to_i == RUBY_VER.segments[0] &&
        minor.to_i == RUBY_VER.segments[1] &&
        ::RUBY_ENGINE == engine
    end
    module_function :actual_minor_version?
  end
end
