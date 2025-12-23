require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/route_helper'
require 'brakeman/util'
require 'brakeman/processors/lib/rails3_route_processor.rb'
require 'brakeman/processors/lib/rails2_route_processor.rb'
require 'set'

class Brakeman::RoutesProcessor
  def self.new tracker
    if tracker.options[:rails3]
      Brakeman::Rails3RoutesProcessor.new tracker
    else
      Brakeman::Rails2RoutesProcessor.new tracker
    end
  end
end
