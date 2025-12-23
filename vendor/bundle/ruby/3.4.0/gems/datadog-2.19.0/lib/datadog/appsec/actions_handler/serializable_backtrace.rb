# frozen_string_literal: true

module Datadog
  module AppSec
    module ActionsHandler
      # This module serves encapsulates MessagePack serialization for caller locations.
      #
      # It serializes part of the stack:
      # up to 32 frames (configurable)
      # keeping frames from top and bottom of the stack (75% to 25%, configurable).
      #
      # It represents the stack trace that is added to span metastruct field.
      class SerializableBacktrace
        CLASS_AND_FUNCTION_NAME_REGEX = /\b((?:\w+::)*\w+)?[#.]?\b(\w+)\z/.freeze

        def initialize(locations:, stack_id:)
          @stack_id = stack_id
          @locations = locations
        end

        def to_msgpack(packer = nil)
          # JRuby doesn't pass the packer
          packer ||= MessagePack::Packer.new

          packer.write_map_header(3)

          packer.write('id')
          packer.write(@stack_id.encode('UTF-8'))

          packer.write('language')
          packer.write('ruby'.encode('UTF-8'))

          serializable_locations_map = build_serializable_locations_map

          packer.write('frames')
          packer.write_array_header(serializable_locations_map.size)

          serializable_locations_map.each do |frame_id, location|
            packer.write_map_header(6)

            packer.write('id')
            packer.write(frame_id)

            packer.write('text')
            packer.write(location.to_s.encode('UTF-8'))

            packer.write('file')
            packer.write(location.path&.encode('UTF-8'))

            packer.write('line')
            packer.write(location.lineno)

            class_name, function_name = location.label&.match(CLASS_AND_FUNCTION_NAME_REGEX)&.captures

            packer.write('class_name')
            packer.write(class_name&.encode('UTF-8'))

            packer.write('function')
            packer.write(function_name&.encode('UTF-8'))
          end

          packer
        end

        private

        def build_serializable_locations_map
          max_depth = Datadog.configuration.appsec.stack_trace.max_depth
          top_percent = Datadog.configuration.appsec.stack_trace.top_percentage

          drop_from_idx = max_depth * top_percent / 100
          drop_until_idx = @locations.size - (max_depth - drop_from_idx)

          frame_idx = -1
          @locations.each_with_object({}) do |location, map|
            # we are dropping frames from library code without increasing frame index
            next if location.path&.include?('lib/datadog')

            frame_idx += 1

            next if max_depth != 0 && frame_idx >= drop_from_idx && frame_idx < drop_until_idx

            map[frame_idx] = location
          end
        end
      end
    end
  end
end
