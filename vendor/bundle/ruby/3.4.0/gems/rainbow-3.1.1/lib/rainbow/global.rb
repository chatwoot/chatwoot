# frozen_string_literal: true

require_relative 'wrapper'

module Rainbow
  def self.global
    @global ||= Wrapper.new
  end

  def self.enabled
    global.enabled
  end

  def self.enabled=(value)
    global.enabled = value
  end

  def self.uncolor(string)
    StringUtils.uncolor(string)
  end
end

def Rainbow(string)
  Rainbow.global.wrap(string.to_s)
end
