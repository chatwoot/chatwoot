# frozen_string_literal: true

require "test_prof/utils/html_builder"

module TestProf::FactoryProf
  module Printers
    module Flamegraph # :nodoc: all
      TEMPLATE = "flamegraph.template.html"
      OUTPUT_NAME = "factory-flame.html"

      class << self
        include TestProf::Logging

        def dump(result, **)
          return log(:info, "No factories detected") if result.raw_stats == {}
          report_data = {
            total_stacks: result.stacks.size,
            total: result.total_count
          }

          report_data[:roots] = convert_stacks(result)

          path = TestProf::Utils::HTMLBuilder.generate(
            data: report_data,
            template: TEMPLATE,
            output: OUTPUT_NAME
          )

          log :info, "FactoryFlame report generated: #{path}"
        end

        def convert_stacks(result)
          res = []

          paths = {}

          result.stacks.each do |stack|
            parent = nil
            path = ""

            stack.each do |sample|
              path = "#{path}/#{sample}"

              if paths[path]
                node = paths[path]
                node[:value] += 1
              else
                node = {
                  name: sample,
                  value: 1,
                  total: result.raw_stats.fetch(sample)[:total_count]
                }
                paths[path] = node

                if parent.nil?
                  res << node
                else
                  parent[:children] ||= []
                  parent[:children] << node
                end
              end

              parent = node
            end
          end

          res
        end
      end
    end
  end
end
