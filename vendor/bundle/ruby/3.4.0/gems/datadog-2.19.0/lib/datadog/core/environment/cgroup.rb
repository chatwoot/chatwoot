# frozen_string_literal: true

require_relative 'ext'

module Datadog
  module Core
    module Environment
      # Reads information from Linux cgroups.
      # This information is used to extract information
      # about the current Linux container identity.
      # @see https://man7.org/linux/man-pages/man7/cgroups.7.html
      module Cgroup
        LINE_REGEX = /^(\d+):([^:]*):(.+)$/.freeze

        Descriptor = Struct.new(
          :id,
          :groups,
          :path,
          :controllers
        )

        module_function

        def descriptors(process = 'self')
          [].tap do |descriptors|
            filepath = "/proc/#{process}/cgroup"

            if File.exist?(filepath)
              File.foreach("/proc/#{process}/cgroup") do |line|
                line = line.strip
                descriptors << parse(line) unless line.empty?
              end
            end
          rescue => e
            Datadog.logger.error(
              "Error while parsing cgroup. Cause: #{e.class.name} #{e.message} Location: #{Array(e.backtrace).first}"
            )
          end
        end

        def parse(line)
          id, groups, path = line.scan(LINE_REGEX).first

          Descriptor.new(id, groups, path).tap do |descriptor|
            descriptor.controllers = groups.split(',') unless groups.nil?
          end
        end
      end
    end
  end
end
