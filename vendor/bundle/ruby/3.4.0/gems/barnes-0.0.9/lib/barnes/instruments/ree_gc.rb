# Copyright (c) 2017 Salesforce
# Copyright (c) 2009 37signals, LLC
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
#  CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

module Barnes
  module Instruments
    class Ruby18GC
      def initialize
        GC.enable_stats
      end

      def start!(state)
        state[:ruby18_gc] = current
      end

      def instrument!(state, counters, gauges)
        last = state[:ruby18_gc]
        cur = state[:ruby18_gc] = current

        counters.update \
          :'GC.count'             => cur[:gc_count] - before[:gc_count],
          :'GC.time'              => cur[:gc_time] - before[:gc_time],
          :'GC.memory'            => cur[:gc_memory] - before[:gc_memory],
          :'GC.allocated_objects' => cur[:objects] - before[:objects]

        gauges[:'Objects.live'] = ObjectSpace.live_objects
        gauges[:'GC.growth'] = GC.growth
      end

      private def current
        {
          :objects   => ObjectSpace.allocated_objects,
          :gc_count  => GC.collections,
          :gc_time   => GC.time,
          :gc_memory => GC.allocated_size
        }
      end
    end
  end
end
