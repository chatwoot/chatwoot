# Copyright 2023 Google LLC
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
  # @private
  #
  # Linked list based hash maintaining the order of
  # access/creation of the keys.
  #
  class LruHash
    def initialize size = 1
      raise ArgumentError, "The size of LRU hash can't be < 1" unless size > 1
      @start = nil
      @end = nil
      @size = size
      @cache = {}
    end

    def get key
      return nil unless @cache.key? key
      node = @cache[key]
      move_to_top node
      node.value
    end

    def put key, value
      if @cache.key? key
        node = @cache[key]
        node.value = value
        move_to_top node
      else
        remove_tail if @cache.size >= @size
        new_node = Node.new key, value
        insert_at_top new_node
        @cache[key] = new_node
      end
    end

    private

    def move_to_top node
      return if node.equal? @start

      if node.equal? @end
        @end = node.prev
        @end.next = nil
      else
        node.prev.next = node.next
        node.next.prev = node.prev
      end

      node.prev = nil
      node.next = @start
      @start.prev = node
      @start = node
    end

    def remove_tail
      @cache.delete @end.key
      @end = @end.prev
      @end.next = nil if @end
    end

    def insert_at_top node
      if @start.nil?
        @start = node
        @end = node
      else
        node.next = @start
        @start.prev = node
        @start = node
      end
    end

    ##
    # @private
    #
    # Node class for linked list.
    #
    class Node
      attr_accessor :key
      attr_accessor :value
      attr_accessor :prev
      attr_accessor :next

      def initialize key, value
        @key = key
        @value = value
        @prev = nil
        @next = nil
      end
    end
  end
end
