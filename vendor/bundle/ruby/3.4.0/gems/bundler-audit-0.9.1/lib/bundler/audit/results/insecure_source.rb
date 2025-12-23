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

module Bundler
  module Audit
    module Results
      #
      # Represents an insecure gem source (ex: `git://...` or `http://...`).
      #
      class InsecureSource < Result

        # The insecure `git://` or `http://` URI.
        #
        # @return [URI::Generic, URI::HTTP]
        attr_reader :source

        #
        # Initializes the insecure source result.
        #
        # @param [URI::Generic, URI::HTTP] source
        #   The insecure `git://` or `http://` URI.
        #
        def initialize(source)
          @source = source
        end

        #
        # Compares the insecure source with another result.
        #
        # @param [Result] other
        #
        # @return [Boolean]
        #
        def ==(other)
          self.class == other.class && @source == other.source
        end

        #
        # Converts the insecure source result to a String.
        #
        # @return [String]
        #
        def to_s
          @source.to_s
        end

        #
        # Converts the insecure source into a Hash.
        #
        # @return [Hash{Symbol => Object}]
        #
        def to_h
          {
            type: :insecure_source,
            source: @source
          }
        end

      end
    end
  end
end
