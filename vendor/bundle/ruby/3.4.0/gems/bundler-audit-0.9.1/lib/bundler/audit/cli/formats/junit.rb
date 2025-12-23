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
require 'cgi'

module Bundler
  module Audit
    class CLI < ::Thor
      module Formats
        module Junit
          #
          # Prints any findings as an XML junit report.
          #
          # @param [Report] report
          #   The results from the {Scanner}.
          #
          # @param [IO, File] output
          #   Optional output stream.
          #
          def print_report(report, output=$stdout)
            original_stdout = $stdout
            $stdout = output

            print_xml_testsuite(report) do
              report.each do |result|
                print_xml_testcase(result)
              end
            end

            $stdout = original_stdout
          end

          private

          def say_xml(*lines)
            say(lines.join($/))
          end

          def print_xml_testsuite(report)
            say_xml(
              %{<?xml version="1.0" encoding="UTF-8" ?>},
              %{<testsuites id="#{Time.now.to_i}" name="Bundle Audit">},
              %{  <testsuite id="Gemfile" name="Ruby Gemfile" failures="#{report.count}">}
            )

            yield

            say_xml(
              %{  </testsuite>},
              %{</testsuites>}
            )
          end

          def xml(string)
            CGI.escapeHTML(string.to_s)
          end

          def print_xml_testcase(result)
            case result
            when Results::InsecureSource
              say_xml(
                %{    <testcase id="#{xml(result.source)}" name="Insecure Source URI found: #{xml(result.source)}">},
                %{      <failure message="Insecure Source URI found: #{xml(result.source)}" type="Unknown"></failure>},
                %{    </testcase>}
              )
            when Results::UnpatchedGem
              say_xml(
                %{    <testcase id="#{xml(result.gem.name)}" name="#{xml(bundle_title(result))}">},
                %{      <failure message="#{xml(result.advisory.title)}" type="#{xml(result.advisory.criticality)}">},
                %{        Name: #{xml(result.gem.name)}},
                %{        Version: #{xml(result.gem.version)}},
                %{        Advisory: #{xml(advisory_ref(result.advisory))}},
                %{        Criticality: #{xml(advisory_criticality(result.advisory))}},
                %{        URL: #{xml(result.advisory.url)}},
                %{        Title: #{xml(result.advisory.title)}},
                %{        Solution: #{xml(advisory_solution(result.advisory))}},
                %{      </failure>},
                %{    </testcase>}
              )
            end
          end

          def bundle_title(result)
            "#{advisory_criticality(result.advisory).upcase} #{result.gem.name}(#{result.gem.version}) #{result.advisory.title}"
          end

          def advisory_solution(advisory)
            unless advisory.patched_versions.empty?
              "upgrade to #{advisory.patched_versions.map { |v| "'#{v}'" }.join(', ')}"
            else
              "remove or disable this gem until a patch is available!"
            end
          end

          def advisory_criticality(advisory)
            if advisory.criticality
              advisory.criticality.to_s.capitalize
            else
              "Unknown"
            end
          end

          def advisory_ref(advisory)
            advisory.identifiers.join(" ")
          end

          Formats.register :junit, Junit
        end
      end
    end
  end
end
