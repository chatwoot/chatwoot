# frozen_string_literal: true

require_relative "helpers/reflection"
require "byebug/byebug"
require_relative "context"
require_relative "breakpoint"
require_relative "interface"
require_relative "processors/script_processor"
require_relative "processors/post_mortem_processor"
require_relative "commands"
require_relative "remote"
require_relative "printers/plain"

#
# Main debugger's container module. Everything is defined under this module
#
module Byebug
  include Helpers::ReflectionHelper

  extend self

  #
  # Configuration file used for startup commands. Default value is .byebugrc
  #
  attr_accessor :init_file
  self.init_file = ".byebugrc"

  #
  # Debugger's display expressions
  #
  attr_accessor :displays
  self.displays = []

  #
  # Running mode of the debugger. Can be either:
  #
  # * :attached => Attached to a running program through the `byebug` method.
  # * :standalone => Started through `byebug` script.
  # * :off => Ignoring any `byebug` method calls.
  #
  attr_accessor :mode

  #
  # Runs normal byebug initialization scripts.
  #
  # Reads and executes the commands from init file (if any) in the current
  # working directory. This is only done if the current directory is different
  # from your home directory. Thus, you can have more than one init file, one
  # generic in your home directory, and another, specific to the program you
  # are debugging, in the directory where you invoke byebug.
  #
  def run_init_script
    rc_dirs.each do |dir|
      rc_file = File.expand_path(File.join(dir, init_file))
      next unless File.exist?(rc_file)

      run_rc_file(rc_file)
    end
  end

  def self.load_settings
    Dir.glob(File.join(__dir__, "settings", "*.rb")).each do |file|
      require file
    end

    constants.grep(/[a-z]Setting/).map do |name|
      setting = const_get(name).new
      Byebug::Setting.settings[setting.to_sym] = setting
    end
  end

  #
  # Saves information about the unhandled exception and gives a byebug
  # prompt back to the user before program termination.
  #
  def self.handle_post_mortem
    return unless raised_exception

    context = raised_exception.__bb_context

    PostMortemProcessor.new(context).at_line
  end

  at_exit { Byebug.handle_post_mortem if Byebug.post_mortem? }

  private

  #
  # Runs a initialization script file
  #
  def run_rc_file(rc_file)
    interface = ScriptInterface.new(rc_file)

    ScriptProcessor.new(nil, interface).process_commands
  end

  #
  # List of folders to load rc files from
  #
  # @note Files will be loaded in the order specified here.
  #
  def rc_dirs
    [ENV["HOME"], Dir.pwd].compact.uniq
  end
end

Byebug.load_settings

#
# Extends the extension class to be able to pass information about the
# debugging environment from the c-extension to the user.
#
class Exception
  attr_reader :__bb_context
end
