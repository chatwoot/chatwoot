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
  DEFAULT_INTERVAL           = 10
  DEFAULT_AGGREGATION_PERIOD = 60
  DEFAULT_STATSD             = :default
  DEFAULT_PANELS             = []


  # Starts the reporting client
  #
  # Arguments:
  #
  #   - interval: How often, in seconds, to instrument and report
  #   - aggregation_period: The minimal aggregation period in use, in seconds.
  #   - statsd: The statsd reporter. This should be an instance of statsd-ruby
  #   - panels: The instrumentation "panels" in use. See `resource_usage.rb` for
  #     an example panel, which is the default if none are provided.
  def self.start(interval: DEFAULT_INTERVAL, aggregation_period: DEFAULT_AGGREGATION_PERIOD, statsd: DEFAULT_STATSD, panels: DEFAULT_PANELS)
    require 'statsd'
    statsd_client = statsd
    panels        = panels
    sample_rate   = interval.to_f / aggregation_period.to_f

    if statsd_client == :default && ENV["PORT"]
      statsd_client = Statsd.new('127.0.0.1', ENV["PORT"])
    end

    if statsd_client && statsd_client != :default
      reporter = Barnes::Reporter.new(statsd: statsd_client, sample_rate: sample_rate)

      unless panels.length > 0
        panels << Barnes::ResourceUsage.new(sample_rate)
      end

      Periodic.new(
        reporter:    reporter,
        sample_rate: sample_rate,
        panels:      panels,
        debug:       ENV['BARNES_DEBUG']
      )
    end
  end
end

require 'barnes/reporter'
require 'barnes/resource_usage'
require 'barnes/periodic'
require 'barnes/railtie' if defined? ::Rails::Railtie
