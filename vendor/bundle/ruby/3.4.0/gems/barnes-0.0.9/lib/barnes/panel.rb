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
  class Panel
    def initialize
      @instruments = []
    end

    # Add an instrument to the Panel
    def instrument(instrument)
      @instruments << instrument
    end

    # Initialize the state of each instrument in the panel.
    def start!(state)
      @instruments.each do |ins|
        ins.start! state if ins.respond_to?(:start!)
      end
    end

    # Read the values of each instrument into counter_readings,
    # and gauge_readings. May have side effects on all arguments.
    def instrument!(state, counter_readings, gauge_readings)
      @instruments.each do |ins|
        ins.instrument! state, counter_readings, gauge_readings
      end
    end
  end
end
