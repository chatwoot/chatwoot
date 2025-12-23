# frozen_string_literal: true

require_relative 'cgroup'

module Datadog
  module Core
    module Environment
      # For container environments
      module Container
        UUID_PATTERN = '[0-9a-f]{8}[-_]?[0-9a-f]{4}[-_]?[0-9a-f]{4}[-_]?[0-9a-f]{4}[-_]?[0-9a-f]{12}'
        CONTAINER_PATTERN = '[0-9a-f]{64}'

        PLATFORM_REGEX = /(?<platform>.*?)(?:.slice)?$/.freeze
        POD_REGEX = /(?<pod>(pod)?#{UUID_PATTERN})(?:.slice)?$/.freeze
        CONTAINER_REGEX = /(?<container>#{UUID_PATTERN}|#{CONTAINER_PATTERN})(?:.scope)?$/.freeze
        FARGATE_14_CONTAINER_REGEX = /(?<container>[0-9a-f]{32}-[0-9]{1,10})/.freeze

        Descriptor = Struct.new(
          :platform,
          :container_id,
          :task_uid
        )

        module_function

        def platform
          descriptor.platform
        end

        def container_id
          descriptor.container_id
        end

        def task_uid
          descriptor.task_uid
        end

        def descriptor
          @descriptor ||= Descriptor.new.tap do |descriptor|
            Cgroup.descriptors.each do |cgroup_descriptor|
              # Parse container data from cgroup descriptor
              path = cgroup_descriptor.path
              next if path.nil?

              # Split path into parts
              parts = path.split('/')
              parts.shift # Remove leading empty part

              # Read info from path
              next if parts.empty?

              platform = parts[0][PLATFORM_REGEX, :platform]
              container_id, task_uid = nil

              case parts.length
              when 0..1
                next
              when 2
                container_id = parts[-1][CONTAINER_REGEX, :container] \
                              || parts[-1][FARGATE_14_CONTAINER_REGEX, :container]
              else
                if (container_id = parts[-1][CONTAINER_REGEX, :container])
                  task_uid = parts[-2][POD_REGEX, :pod] || parts[1][POD_REGEX, :pod]
                else
                  container_id = parts[-1][FARGATE_14_CONTAINER_REGEX, :container]
                end
              end

              # If container ID wasn't found, ignore.
              # Path might describe a non-container environment.
              next if container_id.nil?

              descriptor.platform = platform
              descriptor.container_id = container_id
              descriptor.task_uid = task_uid

              break
            end
          rescue => e
            Datadog.logger.error(
              "Error while parsing container info. Cause: #{e.class.name} #{e.message} " \
              "Location: #{Array(e.backtrace).first}"
            )
          end
        end
      end
    end
  end
end
