# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

# this struct uniquely defines a metric, optionally inside
# the call scope of another metric
class NewRelic::MetricSpec
  attr_reader :name, :scope

  # the maximum length of a metric name or metric scope
  MAX_LENGTH = 255
  LENGTH_RANGE = (0...MAX_LENGTH)
  EMPTY_SCOPE = ''.freeze

  def initialize(metric_name = '', metric_scope = nil)
    if metric_name.to_s.length > MAX_LENGTH
      @name = metric_name.to_s[LENGTH_RANGE]
    else
      @name = metric_name.to_s
    end

    if metric_scope
      if metric_scope.to_s.length > MAX_LENGTH
        @scope = metric_scope.to_s[LENGTH_RANGE]
      else
        @scope = metric_scope.to_s
      end
    else
      @scope = EMPTY_SCOPE
    end
  end

  def ==(o)
    self.eql?(o)
  end

  def eql?(o)
    @name == o.name && @scope == o.scope
  end

  def hash
    [@name, @scope].hash
  end

  def to_s
    return name if scope.empty?

    "#{name}:#{scope}"
  end

  def inspect
    "#<NewRelic::MetricSpec '#{name}':'#{scope}'>"
  end

  def to_json(*a)
    {'name' => name,
     'scope' => scope}.to_json(*a)
  end

  def <=>(o)
    namecmp = self.name <=> o.name
    return namecmp if namecmp != 0

    return (self.scope || '') <=> (o.scope || '')
  end
end
