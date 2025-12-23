# frozen_string_literal: true

module Launchy
  module Detect
    # Detect the current host os family
    #
    # If the current host familiy cannot be detected then return
    # HostOsFamily::Unknown
    class HostOsFamily
      class NotFoundError < Launchy::Error; end
      extend ::Launchy::DescendantTracker

      class << self
        def detect(host_os = HostOs.new)
          found = find_child(:matches?, host_os)
          return found.new(host_os) if found

          raise NotFoundError, "Unknown OS family for host os '#{host_os}'. #{Launchy.bug_report_message}"
        end

        def matches?(host_os)
          matching_regex.match(host_os.to_s)
        end

        def windows?
          self == Windows
        end

        def darwin?
          self == Darwin
        end

        def nix?
          self == Nix
        end

        def cygwin?
          self == Cygwin
        end
      end

      attr_reader :host_os

      def initialize(host_os = HostOs.new)
        @host_os = host_os
      end

      def windows?
        self.class.windows?
      end

      def darwin?
        self.class.darwin?
      end

      def nix?
        self.class.nix?
      end

      def cygwin?
        self.class.cygwin?
      end

      #---------------------------
      # All known host os families
      #---------------------------
      #
      class Windows < HostOsFamily
        def self.matching_regex
          /(mingw|mswin|msys|windows)/i
        end

        def app_list(app)
          app.windows_app_list
        end
      end

      # Mac OS X family
      class Darwin < HostOsFamily
        def self.matching_regex
          /(darwin|mac os)/i
        end

        def app_list(app)
          app.darwin_app_list
        end
      end

      # All the *nix family of operating systems, and BSDs
      class Nix < HostOsFamily
        def self.matching_regex
          /(linux|bsd|aix|solaris|sunos|dragonfly)/i
        end

        def app_list(app)
          app.nix_app_list
        end
      end

      # Cygwin - if anyone is still using that
      class Cygwin < HostOsFamily
        def self.matching_regex
          /cygwin/i
        end

        def app_list(app)
          app.cygwin_app_list
        end
      end
    end
  end
end
