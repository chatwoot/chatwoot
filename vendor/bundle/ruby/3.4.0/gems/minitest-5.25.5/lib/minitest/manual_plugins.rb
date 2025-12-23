require "minitest"

ARGV << "--no-plugins"

module Minitest
  ##
  # Manually load plugins by name.

  def self.load *names
    names.each do |name|
      require "minitest/#{name}_plugin"

      self.extensions << name.to_s
    end
  end
end
