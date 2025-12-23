require "spring/watcher/abstract"
require "spring/configuration"

module Spring
  class << self
    attr_accessor :watch_interval
    attr_writer :watcher
    attr_reader :watch_method
  end

  def self.watch_method=(method)
    if method.is_a?(Class)
      @watch_method = method
    else
      require "spring/watcher/#{method}"
      @watch_method = Watcher.const_get(method.to_s.gsub(/(^.|_.)/) { $1[-1].upcase })
    end
  end

  self.watch_interval = 0.2
  self.watch_method = :polling

  def self.watcher
    @watcher ||= watch_method.new(Spring.application_root_path, watch_interval)
  end

  def self.watch(*items)
    watcher.add(*items)
  end
end
