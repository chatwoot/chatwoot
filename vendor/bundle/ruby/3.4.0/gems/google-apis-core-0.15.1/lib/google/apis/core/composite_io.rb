# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# Copyright 2015 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/apis/core/http_command'
require 'google/apis/core/upload'
require 'google/apis/core/download'
require 'addressable/uri'
require 'securerandom'
module Google
  module Apis
    module Core
      class CompositeIO
        def initialize(*ios)
          @ios = ios.flatten
          @pos = 0
          @index = 0
          @sizes = @ios.map(&:size)
        end

        def read(length = nil, buf = nil)
          buf = buf ? buf.replace('') : ''

          begin
            io = @ios[@index]
            break if io.nil?
            result = io.read(length)
            if result
              buf << result
              if length
                length -= result.length
                break if length == 0
              end
            end
            @index += 1
          end while @index < @ios.length
          buf.length > 0 ? buf : nil
        end

        def size
          @sizes.reduce(:+)
        end

        alias_method :length, :size

        def pos
          @pos
        end

        def pos=(pos)
          fail ArgumentError, "Position can not be negative" if pos < 0
          @pos = pos
          new_index = nil
          @ios.each_with_index do |io,idx|
            size = io.size
            if pos <= size
              new_index ||= idx
              io.pos = pos
              pos = 0
            else
              io.pos = size
              pos -= size
            end
          end
          @index = new_index unless new_index.nil?
        end

        def rewind
          self.pos = 0
        end
      end
    end
  end
end