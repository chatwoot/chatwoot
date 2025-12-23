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
    # Tracks out of band GCs that occurred *since* the last request.
    class GctoolsOobgc
      def start!(state)
        state[:oobgc] = current
      end

      def instrument!(state, counters, gauges)
        last = state[:oobgc]
        cur = state[:oobgc] = current

        counters.update \
          :'OOBGC.count'        => cur[:count] - last[:count],
          :'OOBGC.major_count'  => cur[:major] - last[:major],
          :'OOBGC.minor_count'  => cur[:minor] - last[:minor],
          :'OOBGC.sweep_count'  => cur[:sweep] - last[:sweep]
      end

      private def current
        {
          :count => GC::OOB.stat(:count).to_i,
          :major => GC::OOB.stat(:major).to_i,
          :minor => GC::OOB.stat(:minor).to_i,
          :sweep => GC::OOB.stat(:sweep).to_i
        }
      end
    end
  end
end
