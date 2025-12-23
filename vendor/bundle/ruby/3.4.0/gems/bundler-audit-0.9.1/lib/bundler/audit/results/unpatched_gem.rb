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

require 'bundler/audit/results/result'

require 'uri'

module Bundler
  module Audit
    module Results
      #
      # Represents a gem version that has known vulnerabilities and needs to be
      # upgraded.
      #
      class UnpatchedGem < Result

        # The specification of the vulnerable gem.
        #
        # @return [Gem::Specification]
        attr_reader :gem

        # The advisory documenting the vulnerability.
        #
        # @return [Advisory]
        attr_reader :advisory

        #
        # Initializes the unpatched gem result.
        #
        # @param [Gem::Specification] gem
        #   The specification of the vulnerable gem.
        #
        # @param [Advisory] advisory
        #   The advisory documenting the vulnerability.
        #
        def initialize(gem,advisory)
          @gem      = gem
          @advisory = advisory
        end

        #
        # Compares the unpatched gem to another result.
        #
        # @param [Result] other
        #
        # @return [Boolean]
        #
        def ==(other)
          self.class == other.class && (
            @gem.name == other.gem.name &&
            @gem.version == other.gem.version &&
            @advisory == other.advisory
          )
        end

        #
        # Converts the unpatched gem result into a String.
        #
        # @return [String]
        #
        def to_s
          @advisory.id
        end

        #
        # Converts the unpatched gem to a Hash.
        #
        # @return [Hash{Symbol => Object}]
        #
        def to_h
          {
            type: :unpatched_gem,
            gem:  {
              name: @gem.name,
              version: @gem.version
            },
            advisory: @advisory.to_h
          }
        end

      end
    end
  end
end
