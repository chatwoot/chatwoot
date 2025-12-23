# Copyright 2022 Google LLC
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

require "json"

module Gapic
  module Rest
    ##
    # A class to provide the Enumerable interface to the response of a REST server-streaming dmethod.
    #
    # ServerStream provides the enumerations over the individual response messages within the stream.
    #
    # @example normal iteration over resources.
    #   server_stream.each { |response| puts response }
    #
    class ServerStream
      include Enumerable

      ##
      # Initializes ServerStream object.
      #
      # @param message_klass [Class]
      # @param json_enumerator [Enumerator<String>]
      def initialize message_klass, json_enumerator
        @json_enumerator = json_enumerator
        @obj = ""
        @message_klass = message_klass
        @ready_objs = [] # List of strings
      end

      ##
      # Iterate over JSON objects in the streamed response.
      #
      # @yield [Object] Gives one complete Message object.
      #
      # @return [Enumerator] if no block is provided
      #
      def each
        return enum_for :each unless block_given?

        loop do
          while @ready_objs.empty?
            begin
              chunk = @json_enumerator.next
              next unless chunk
              next_json! chunk
            rescue StopIteration
              dangling_content = @obj.strip
              error_expl = "Dangling content left after iterating through the stream. " \
                           "This means that not all content was received or parsed correctly. " \
                           "It is likely a result of server or network error."
              error_text = "#{error_expl}\n Content left unparsed: #{dangling_content}"

              raise Gapic::Common::Error, error_text unless dangling_content.empty?
              return
            end
          end
          yield @message_klass.decode_json @ready_objs.shift, ignore_unknown_fields: true
        end
      end

      private

      ##
      # Builds the next JSON object of the server stream from chunk.
      #
      # @param chunk [String] Contains (partial) JSON object
      #
      def next_json! chunk
        chunk.chars.each do |char|
          # Invariant: @obj is always either a part of a single JSON object or the entire JSON object.
          # Hence, it's safe to strip whitespace, commans and array brackets. These characters
          # are only added before @obj is a complete JSON object and essentially can be flushed.
          next if @obj.empty? && char != "{"
          @obj += char
          next unless char == "}"
          begin
            # Two choices here: append a Ruby object into
            # ready_objs or a string. Going with the latter here.
            JSON.parse @obj
            @ready_objs.append @obj
            @obj = ""
          rescue JSON::ParserError
            next
          end
        end
      end
    end
  end
end
