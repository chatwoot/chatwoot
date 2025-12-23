#
# Copyright (c) 2013-2022 Hal Brodigan (postmodern.mod3 at gmail.com)
#
# bundler-audit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# bundler-audit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with bundler-audit.  If not, see <https://www.gnu.org/licenses/>.
#

require 'bundler'
require 'bundler/audit/configuration'
require 'bundler/audit/database'
require 'bundler/audit/report'
require 'bundler/audit/results/insecure_source'
require 'bundler/audit/results/unpatched_gem'
require 'bundler/lockfile_parser'

require 'ipaddr'
require 'resolv'
require 'set'
require 'uri'
require 'yaml'

module Bundler
  module Audit
    #
    # Scans a `Gemfile.lock` for security issues.
    #
    class Scanner

      # The advisory database.
      #
      # @return [Database]
      attr_reader :database

      # Project root directory
      attr_reader :root

      # The parsed `Gemfile.lock` from the project.
      #
      # @return [Bundler::LockfileParser]
      attr_reader :lockfile

      # The configuration loaded from the `.bundler-audit.yml` file from the
      # project.
      #
      # @return [Hash]
      attr_reader :config

      #
      # Initializes a scanner.
      #
      # @param [String] root
      #   The path to the project root.
      #
      # @param [String] gemfile_lock
      #   Alternative name for the `Gemfile.lock` file.
      #
      # @param [Database] database
      #   The database to scan against.
      #
      # @param [String] config_dot_file
      #   The file name of the bundler-audit config file.
      #
      # @raise [Bundler::GemfileLockNotFound]
      #   The `gemfile_lock` file could not be found within the `root`
      #   directory.
      #
      def initialize(root=Dir.pwd,gemfile_lock='Gemfile.lock',database=Database.new,config_dot_file='.bundler-audit.yml')
        @root     = File.expand_path(root)
        @database = database

        gemfile_lock_path = File.join(@root,gemfile_lock)

        unless File.file?(gemfile_lock_path)
          raise(Bundler::GemfileLockNotFound,"Could not find #{gemfile_lock.inspect} in #{@root.inspect}")
        end

        @lockfile = LockfileParser.new(File.read(gemfile_lock_path))

        config_dot_file_full_path = File.absolute_path(config_dot_file, @root)

        @config = if File.exist?(config_dot_file_full_path)
                    Configuration.load(config_dot_file_full_path)
                  else
                    Configuration.new
                  end
      end

      #
      # Preforms a {#scan} and collects the results into a {Report report}.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [Array<String>] :ignore
      #   The advisories to ignore.
      #
      # @yield [result]
      #   The given block will be passed the results of the scan.
      #
      # @yieldparam [Results::InsecureSource, Results::UnpatchedGem] result
      #   A result from the scan.
      #
      # @return [Report]
      #
      # @since 0.8.0
      #
      def report(options={})
        report = Report.new()

        scan(options) do |result|
          report << result
          yield result if block_given?
        end

        return report
      end

      #
      # Scans the project for issues.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [Array<String>] :ignore
      #   The advisories to ignore.
      #
      # @yield [result]
      #   The given block will be passed the results of the scan.
      #
      # @yieldparam [Results::InsecureSource, Results::UnpatchedGem] result
      #   A result from the scan.
      #
      # @return [Enumerator]
      #   If no block is given, an Enumerator will be returned.
      #
      def scan(options={},&block)
        return enum_for(__method__,options) unless block

        scan_sources(options,&block)
        scan_specs(options,&block)

        return self
      end

      #
      # Scans the gem sources in the lockfile.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @yield [result]
      #   The given block will be passed the results of the scan.
      #
      # @yieldparam [Results::InsecureSource] result
      #   A result from the scan.
      #
      # @return [Enumerator]
      #   If no block is given, an Enumerator will be returned.
      #
      # @api semipublic
      #
      # @since 0.4.0
      #
      def scan_sources(options={})
        return enum_for(__method__,options) unless block_given?

        @lockfile.sources.map do |source|
          case source
          when Source::Git
            case source.uri
            when /^git:/, /^http:/
              unless internal_source?(source.uri)
                yield Results::InsecureSource.new(source.uri)
              end
            end
          when Source::Rubygems
            source.remotes.each do |uri|
              if (uri.scheme == 'http' && !internal_source?(uri))
                yield Results::InsecureSource.new(uri.to_s)
              end
            end
          end
        end
      end

      #
      # Scans the gem sources in the lockfile.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [Array<String>] :ignore
      #   The advisories to ignore.
      #
      # @yield [result]
      #   The given block will be passed the results of the scan.
      #
      # @yieldparam [Results::UnpatchedGem] result
      #   A result from the scan.
      #
      # @return [Enumerator]
      #   If no block is given, an Enumerator will be returned.
      #
      # @api semipublic
      #
      # @since 0.4.0
      #
      def scan_specs(options={})
        return enum_for(__method__,options) unless block_given?

        ignore = if options[:ignore]
                   Set.new(options[:ignore])
                 else
                   config.ignore
                 end

        @lockfile.specs.each do |gem|
          @database.check_gem(gem) do |advisory|
            is_ignored = ignore.intersect?(advisory.identifiers.to_set)
            next if is_ignored

            yield Results::UnpatchedGem.new(gem,advisory)
          end
        end
      end

      private

      #
      # Determines whether a source is internal.
      #
      # @param [URI, String] uri
      #   The URI.
      #
      # @return [Boolean]
      #
      def internal_source?(uri)
        uri = URI.parse(uri.to_s)

        internal_host?(uri.host) if uri.host
      end

      #
      # Determines whether a host is internal.
      #
      # @param [String] host
      #   The hostname.
      #
      # @return [Boolean]
      #
      def internal_host?(host)
        Resolv.getaddresses(host).all? { |ip| internal_ip?(ip) }
      rescue URI::Error
        false
      end

      # List of internal IP address ranges.
      #
      # @see https://tools.ietf.org/html/rfc1918#section-3
      # @see https://tools.ietf.org/html/rfc4193#section-8
      # @see https://tools.ietf.org/html/rfc6890#section-2.2.2
      # @see https://tools.ietf.org/html/rfc6890#section-2.2.3
      INTERNAL_SUBNETS = %w[
        10.0.0.0/8
        172.16.0.0/12
        192.168.0.0/16
        fc00::/7
        127.0.0.0/8
        ::1/128
      ].map(&IPAddr.method(:new))

      #
      # Determines whether an IP is internal.
      #
      # @param [String] ip
      #   The IPv4/IPv6 address.
      #
      # @return [Boolean]
      #
      def internal_ip?(ip)
        INTERNAL_SUBNETS.any? { |subnet| subnet.include?(ip) }
      end
    end
  end
end
