require 'rbconfig'

module RestClient
  module Platform
    # Return true if we are running on a darwin-based Ruby platform. This will
    # be false for jruby even on OS X.
    #
    # @return [Boolean]
    def self.mac_mri?
      RUBY_PLATFORM.include?('darwin')
    end

    # Return true if we are running on Windows.
    #
    # @return [Boolean]
    #
    def self.windows?
      # Ruby only sets File::ALT_SEPARATOR on Windows, and the Ruby standard
      # library uses that to test what platform it's on.
      !!File::ALT_SEPARATOR
    end

    # Return true if we are running on jruby.
    #
    # @return [Boolean]
    #
    def self.jruby?
      # defined on mri >= 1.9
      RUBY_ENGINE == 'jruby'
    end

    def self.architecture
      "#{RbConfig::CONFIG['host_os']} #{RbConfig::CONFIG['host_cpu']}"
    end

    def self.ruby_agent_version
      case RUBY_ENGINE
      when 'jruby'
        "jruby/#{JRUBY_VERSION} (#{RUBY_VERSION}p#{RUBY_PATCHLEVEL})"
      else
        "#{RUBY_ENGINE}/#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
      end
    end

    def self.default_user_agent
      "rest-client/#{VERSION} (#{architecture}) #{ruby_agent_version}"
    end
  end
end
