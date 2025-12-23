# frozen_string_literal: true

require 'rbconfig'

class Pry
  module Helpers
    # Contains methods for querying the platform that Pry is running on
    # @api public
    # @since v0.12.0
    module Platform
      # @return [Boolean]
      def self.mac_osx?
        !!(RbConfig::CONFIG['host_os'] =~ /\Adarwin/i)
      end

      # @return [Boolean]
      def self.linux?
        !!(RbConfig::CONFIG['host_os'] =~ /linux/i)
      end

      # @return [Boolean] true when Pry is running on Windows with ANSI support,
      #   false otherwise
      def self.windows?
        !!(RbConfig::CONFIG['host_os'] =~ /mswin|mingw/)
      end

      # @return [Boolean]
      def self.windows_ansi?
        return false unless windows?

        !!(defined?(Win32::Console) || Pry::Env['ANSICON'] || mri?)
      end

      # @return [Boolean]
      def self.jruby?
        RbConfig::CONFIG['ruby_install_name'] == 'jruby'
      end

      # @return [Boolean]
      def self.jruby_19?
        jruby? && RbConfig::CONFIG['ruby_version'] == '1.9'
      end

      # @return [Boolean]
      def self.mri?
        RbConfig::CONFIG['ruby_install_name'] == 'ruby'
      end

      # @return [Boolean]
      def self.mri_2?
        mri? && RUBY_VERSION.start_with?('2')
      end
    end
  end
end
