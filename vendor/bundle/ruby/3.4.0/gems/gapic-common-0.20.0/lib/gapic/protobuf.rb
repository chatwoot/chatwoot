# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "google/protobuf/timestamp_pb"

module Gapic
  ##
  # A set of internal utilities for coercing data to protobuf messages.
  #
  module Protobuf
    ##
    # Creates an instance of a protobuf message from a hash that may include nested hashes. `google/protobuf` allows
    # for the instantiation of protobuf messages using hashes but does not allow for nested hashes to instantiate
    # nested submessages.
    #
    # @param hash [Hash, Object] The hash to be converted into a proto message. If an instance of the proto message
    #   class is given, it is returned unchanged.
    # @param to [Class] The corresponding protobuf message class of the given hash.
    #
    # @return [Object] An instance of the given message class.
    def self.coerce hash, to:
      return hash if hash.is_a? to
      return nil if hash.nil?

      # Special case handling of certain types
      return time_to_timestamp hash if to == Google::Protobuf::Timestamp && hash.is_a?(Time)

      # Sanity check: input must be a Hash
      raise ArgumentError, "Value #{hash} must be a Hash or a #{to.name}" unless hash.is_a? Hash

      hash = coerce_submessages hash, to.descriptor
      to.new hash
    end

    ##
    # Coerces values of the given hash to be acceptable by the instantiation method provided by `google/protobuf`
    #
    # @private
    #
    # @param hash [Hash] The hash whose nested hashes will be coerced.
    # @param message_descriptor [Google::Protobuf::Descriptor] The protobuf descriptor for the message.
    #
    # @return [Hash] A hash whose nested hashes have been coerced.
    def self.coerce_submessages hash, message_descriptor
      return nil if hash.nil?
      coerced = {}
      hash.each do |key, val|
        field_descriptor = message_descriptor.lookup key.to_s
        coerced[key] =
          if field_descriptor&.type == :message
            coerce_submessage val, field_descriptor
          elsif field_descriptor&.type == :bytes && (val.is_a?(IO) || val.is_a?(StringIO))
            val.binmode.read
          else
            # For non-message fields, just pass the scalar value through.
            # Note: if field_descriptor is not found, we just pass the value
            # through and let protobuf raise an error.
            val
          end
      end
      coerced
    end

    ##
    # Coerces a message-typed field.
    # The field can be a normal single message, a repeated message, or a map.
    #
    # @private
    #
    # @param val [Object] The value to coerce
    # @param field_descriptor [Google::Protobuf::FieldDescriptor] The field descriptor.
    #
    def self.coerce_submessage val, field_descriptor
      if val.is_a? Array
        # Assume this is a repeated message field, iterate over it and coerce
        # each to the message class.
        # Protobuf will raise an error if this assumption is incorrect.
        val.map do |elem|
          coerce elem, to: field_descriptor.subtype.msgclass
        end
      elsif field_descriptor.label == :repeated
        # Non-array passed to a repeated field: assume this is a map, and that
        # a hash is being passed, and let protobuf handle the conversion.
        # Protobuf will raise an error if this assumption is incorrect.
        val
      else
        # Assume this is a normal single message, and coerce to the message
        # class.
        coerce val, to: field_descriptor.subtype.msgclass
      end
    end

    ##
    # Utility for converting a Google::Protobuf::Timestamp instance to a Ruby time.
    #
    # @param timestamp [Google::Protobuf::Timestamp] The timestamp to be converted.
    #
    # @return [Time] The converted Time.
    def self.timestamp_to_time timestamp
      Time.at timestamp.seconds, timestamp.nanos, :nanosecond
    end

    ##
    # Utility for converting a Ruby Time instance to a Google::Protobuf::Timestamp.
    #
    # @param time [Time] The Time to be converted.
    #
    # @return [Google::Protobuf::Timestamp] The converted Google::Protobuf::Timestamp.
    def self.time_to_timestamp time
      Google::Protobuf::Timestamp.new seconds: time.to_i, nanos: time.nsec
    end

    private_class_method :coerce_submessages, :coerce_submessage
  end
end
