# frozen_string_literal: true

require 'ruby-progressbar/base'
require 'ruby-progressbar/refinements' if Module.
                                         private_instance_methods.
                                         include?(:using)

class ProgressBar
  def self.create(*args)
    ProgressBar::Base.new(*args)
  end
end
