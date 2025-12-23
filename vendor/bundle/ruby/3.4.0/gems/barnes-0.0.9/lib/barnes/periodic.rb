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

require 'barnes/consts'

module Barnes
  # The periodic class is used to send occasional metrics
  # to a reporting instance of `Barnes::Reporter` at a semi-regular
  # rate.
  class Periodic
    def initialize(reporter:, sample_rate: 1, debug: false, panels: [])
      @reporter = reporter
      @reporter.sample_rate = sample_rate
      @debug = debug
      # compute interval based on a 60s reporting phase.
      @interval = sample_rate * 60.0
      @panels = panels

      @thread = Thread.new {
        Thread.current[:barnes_state] = {}

        @panels.each do |panel|
          panel.start! Thread.current[:barnes_state]
        end

        loop do
          begin
            sleep @interval

            # read the current values
            env = {
              STATE    => Thread.current[:barnes_state],
              COUNTERS => {},
              GAUGES   => {}
            }

            @panels.each do |panel|
              panel.instrument! env[STATE], env[COUNTERS], env[GAUGES]
            end

            puts env.to_json if @debug
            @reporter.report env
          end
        end
      }
      @thread.abort_on_exception = true
    end

    def stop
      @thread.exit
    end
  end
end
