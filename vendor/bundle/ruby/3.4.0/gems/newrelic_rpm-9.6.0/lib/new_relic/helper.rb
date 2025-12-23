# This file is distributed under New Relic's license terms.
# See https://github.com/newrelic/newrelic-ruby-agent/blob/main/LICENSE for complete details.
# frozen_string_literal: true

require 'new_relic/language_support'
require 'open3'

module NewRelic
  class CommandExecutableNotFoundError < StandardError; end
  class CommandRunFailedError < StandardError; end

  # A singleton for shared generic helper methods
  module Helper
    extend self

    # Confirm a string is correctly encoded,
    # If not force the encoding to ASCII-8BIT (binary)
    def correctly_encoded(string)
      return string unless string.is_a?(String)

      # The .dup here is intentional, since force_encoding mutates the target,
      # and we don't know who is going to use this string downstream of us.
      string.valid_encoding? ? string : string.dup.force_encoding(Encoding::ASCII_8BIT)
    end

    def instance_method_visibility(klass, method_name)
      if klass.private_instance_methods.map { |s| s.to_sym }.include?(method_name.to_sym)
        :private
      elsif klass.protected_instance_methods.map { |s| s.to_sym }.include?(method_name.to_sym)
        :protected
      else
        :public
      end
    end

    def instance_methods_include?(klass, method_name)
      method_name_sym = method_name.to_sym
      (
        klass.instance_methods.map { |s| s.to_sym }.include?(method_name_sym) ||
        klass.protected_instance_methods.map { |s| s.to_sym }.include?(method_name_sym) ||
        klass.private_instance_methods.map { |s| s.to_sym }.include?(method_name_sym)
      )
    end

    def time_to_millis(time)
      (time.to_f * 1000).round
    end

    def run_command(command)
      executable = command.split(' ').first
      unless executable_in_path?(executable)
        raise NewRelic::CommandExecutableNotFoundError.new("Executable not found: '#{executable}'")
      end

      exception = nil
      begin
        output, status = Open3.capture2e(command)
      rescue => exception
      end

      if exception || !status.success?
        message = exception ? "#{exception.class} - #{exception.message}" : output
        raise NewRelic::CommandRunFailedError.new("Failed to run command '#{command}': #{message}")
      end

      # needs else branch coverage
      output.chomp if output # rubocop:disable Style/SafeNavigation
    end

    # TODO: Open3 defers the actual execution of a binary to Process.spawn,
    #       which will raise an Errno::ENOENT exception for a file that
    #       cannot be found. We might want to take the time to evaluate
    #       relying on that Process.spawn behavior instead of checking for
    #       existence ourselves. We'd need to see what it does, how efficient
    #       it is, if it differs in functionality between Ruby versions and
    #       operating systems, etc.
    def executable_in_path?(executable)
      return false unless ENV['PATH']

      ENV['PATH'].split(File::PATH_SEPARATOR).any? do |bin_path|
        executable_path = File.join(bin_path, executable)
        File.exist?(executable_path) && File.file?(executable_path) && File.executable?(executable_path)
      end
    end
  end
end
