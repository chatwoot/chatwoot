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

require 'date'
require 'yaml'

module Bundler
  module Audit
    #
    # Represents an advisory loaded from the {Database}.
    #
    class Advisory < Struct.new(:path,
                                :id,
                                :url,
                                :title,
                                :date,
                                :description,
                                :cvss_v2,
                                :cvss_v3,
                                :cve,
                                :osvdb,
                                :ghsa,
                                :unaffected_versions,
                                :patched_versions)

      #
      # Loads the advisory from a YAML file.
      #
      # @param [String] path
      #   The path to the advisory YAML file.
      #
      # @return [Advisory]
      #
      # @api semipublic
      #
      def self.load(path)
        id   = File.basename(path).chomp('.yml')
        data = File.open(path) do |yaml|
                 if Psych::VERSION >= '3.1.0'
                   YAML.safe_load(yaml, permitted_classes: [Date])
                 else
                   # XXX: psych < 3.1.0 YAML.safe_load calling convention
                   YAML.safe_load(yaml, [Date])
                 end
               end

        unless data.kind_of?(Hash)
          raise("advisory data in #{path.dump} was not a Hash")
        end

        parse_versions = lambda { |versions|
          Array(versions).map do |version|
            Gem::Requirement.new(*version.split(', '))
          end
        }

        return new(
          path,
          id,
          data['url'],
          data['title'],
          data['date'],
          data['description'],
          data['cvss_v2'],
          data['cvss_v3'],
          data['cve'],
          data['osvdb'],
          data['ghsa'],
          parse_versions[data['unaffected_versions']],
          parse_versions[data['patched_versions']]
        )
      end

      #
      # The CVE identifier.
      #
      # @return [String, nil]
      #
      def cve_id
        "CVE-#{cve}" if cve
      end

      #
      # The OSVDB identifier.
      #
      # @return [String, nil]
      #
      def osvdb_id
        "OSVDB-#{osvdb}" if osvdb
      end

      #
      # The GHSA (GitHub Security Advisory) identifier
      #
      # @return [String, nil]
      #
      # @since 0.7.0
      #
      def ghsa_id
        "GHSA-#{ghsa}" if ghsa
      end

      #
      # Return a compacted list of all ids
      #
      # @return [Array<String>]
      #
      # @since 0.7.0
      #
      def identifiers
        [
          cve_id,
          osvdb_id,
          ghsa_id
        ].compact
      end

      #
      # Determines how critical the vulnerability is.
      #
      # @return [:none, :low, :medium, :high, :critical, nil]
      #   The criticality of the vulnerability based on the CVSS score.
      #
      def criticality
        if cvss_v3
          case cvss_v3
          when 0.0       then :none
          when 0.1..3.9  then :low
          when 4.0..6.9  then :medium
          when 7.0..8.9  then :high
          when 9.0..10.0 then :critical
          end
        elsif cvss_v2
          case cvss_v2
          when 0.0..3.9  then :low
          when 4.0..6.9  then :medium
          when 7.0..10.0 then :high
          end
        end
      end

      #
      # Checks whether the version is not affected by the advisory.
      #
      # @param [Gem::Version] version
      #   The version to compare against {#unaffected_versions}.
      #
      # @return [Boolean]
      #   Specifies whether the version is not affected by the advisory.
      #
      # @since 0.2.0
      #
      def unaffected?(version)
        unaffected_versions.any? do |unaffected_version|
          unaffected_version === version
        end
      end

      #
      # Checks whether the version is patched against the advisory.
      #
      # @param [Gem::Version] version
      #   The version to compare against {#patched_versions}.
      #
      # @return [Boolean]
      #   Specifies whether the version is patched against the advisory.
      #
      # @since 0.2.0
      #
      def patched?(version)
        patched_versions.any? do |patched_version|
          patched_version === version
        end
      end

      #
      # Checks whether the version is vulnerable to the advisory.
      #
      # @param [Gem::Version] version
      #   The version to compare against {#patched_versions}.
      #
      # @return [Boolean]
      #   Specifies whether the version is vulnerable to the advisory or not.
      #
      def vulnerable?(version)
        !patched?(version) && !unaffected?(version)
      end

      #
      # Compares two advisories.
      #
      # @param [Advisory] other
      #
      # @return [Boolean]
      #
      def ==(other)
        id == other.id
      end

      #
      # Converts the advisory to a Hash.
      #
      # @return [Hash{Symbol => Object}]
      #
      def to_h
        super.merge({
          criticality: criticality
        })
      end

      alias to_s id

    end
  end
end
