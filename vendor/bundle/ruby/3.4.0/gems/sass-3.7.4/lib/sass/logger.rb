module Sass::Logger; end

require "sass/logger/log_level"
require "sass/logger/base"
require "sass/logger/delayed"

module Sass
  class << self
    def logger=(l)
      Thread.current[:sass_logger] = l
    end

    def logger
      Thread.current[:sass_logger] ||= Sass::Logger::Base.new
    end
  end
end
