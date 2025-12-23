require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/rails4_config_processor.rb'
require 'brakeman/processors/lib/rails3_config_processor.rb'
require 'brakeman/processors/lib/rails2_config_processor.rb'

class Brakeman::ConfigProcessor
  def self.new tracker
    if tracker.options[:rails4]
      Brakeman::Rails4ConfigProcessor.new tracker
    elsif tracker.options[:rails3]
      Brakeman::Rails3ConfigProcessor.new tracker
    else
      Brakeman::Rails2ConfigProcessor.new tracker
    end
  end
end
