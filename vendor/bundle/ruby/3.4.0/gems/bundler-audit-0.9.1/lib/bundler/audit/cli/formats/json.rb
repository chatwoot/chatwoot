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

require 'thor'
require 'json'

module Bundler
  module Audit
    class CLI < ::Thor
      module Formats
        #
        # The JSON output format.
        #
        module JSON
          #
          # Outputs the report as JSON. Will pretty-print JSON if `output`
          # is a TTY, otherwise normal JSON will be outputted.
          #
          # @param [Report] report
          #   The results from the {Scanner}.
          #
          # @param [IO, File] output
          #   The output stream.
          #
          def print_report(report,output=$stdout)
            hash = report.to_h

            if output.tty?
              output.puts(::JSON.pretty_generate(hash))
            else
              output.write(::JSON.generate(hash))
            end
          end

          def criticality_label(advisory)
            case advisory.criticality
            when :none     then "none"
            when :low      then "low"
            when :medium   then "medium"
            when :high     then "high"
            when :critical then "critical"
            else "unknown"
            end
          end
        end

        Formats.register :json, JSON
      end
    end
  end
end
