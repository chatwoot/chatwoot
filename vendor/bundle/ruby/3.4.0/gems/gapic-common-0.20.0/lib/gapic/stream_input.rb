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

module Gapic
  ##
  # Manages requests for an input stream and holds the stream open until {#close} is called.
  #
  class StreamInput
    ##
    # Create a new input stream object to manage streaming requests and hold the stream open until {#close} is called.
    #
    # @param requests [Object]
    #
    def initialize *requests
      @queue = Queue.new

      # Push initial requests into the queue
      requests.each { |request| @queue.push request }
    end

    ##
    # Adds a request object to the stream.
    #
    # @param request [Object]
    #
    # @return [StreamInput] Returns self.
    #
    def push request
      @queue.push request

      self
    end
    alias << push
    alias append push

    ##
    # Closes the stream.
    #
    # @return [StreamInput] Returns self.
    #
    def close
      @queue.push self

      self
    end

    ##
    # @private
    # Iterates the requests given to the stream.
    #
    # @yield [request] The block for accessing each request.
    # @yieldparam [Object] request The request object.
    #
    # @return [Enumerator] An Enumerator is returned if no block is given.
    #
    def to_enum
      return enum_for :to_enum unless block_given?
      loop do
        request = @queue.pop
        break if request.equal? self
        yield request
      end
    end
  end
end
