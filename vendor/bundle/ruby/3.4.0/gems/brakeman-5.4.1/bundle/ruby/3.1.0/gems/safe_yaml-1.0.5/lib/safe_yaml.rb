require "safe_yaml/load"

module YAML
  def self.load_with_options(yaml, *original_arguments)
    filename, options = filename_and_options_from_arguments(original_arguments)
    safe_mode = safe_mode_from_options("load", options)
    arguments = [yaml]

    if safe_mode == :safe
      arguments << filename if SafeYAML::YAML_ENGINE == "psych"
      arguments << options_for_safe_load(options)
      safe_load(*arguments)
    else
      arguments << filename if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
      unsafe_load(*arguments)
    end
  end

  def self.load_file_with_options(file, options={})
    safe_mode = safe_mode_from_options("load_file", options)
    if safe_mode == :safe
      safe_load_file(file, options_for_safe_load(options))
    else
      unsafe_load_file(file)
    end
  end

  def self.safe_load(*args)
    SafeYAML.load(*args)
  end

  def self.safe_load_file(*args)
    SafeYAML.load_file(*args)
  end

  if SafeYAML::MULTI_ARGUMENT_YAML_LOAD
    def self.unsafe_load_file(filename)
      # https://github.com/tenderlove/psych/blob/v1.3.2/lib/psych.rb#L296-298
      File.open(filename, 'r:bom|utf-8') { |f| self.unsafe_load(f, filename) }
    end

  else
    def self.unsafe_load_file(filename)
      # https://github.com/tenderlove/psych/blob/v1.2.2/lib/psych.rb#L231-233
      self.unsafe_load File.open(filename)
    end
  end

  class << self
    alias_method :unsafe_load, :load
    alias_method :load, :load_with_options
    alias_method :load_file, :load_file_with_options

    private
    def filename_and_options_from_arguments(arguments)
      if arguments.count == 1
        if arguments.first.is_a?(String)
          return arguments.first, {}
        else
          return nil, arguments.first || {}
        end

      else
        return arguments.first, arguments.last || {}
      end
    end

    def safe_mode_from_options(method, options={})
      if options[:safe].nil?
        safe_mode = SafeYAML::OPTIONS[:default_mode] || :safe

        if SafeYAML::OPTIONS[:default_mode].nil? && !SafeYAML::OPTIONS[:suppress_warnings]

          Kernel.warn <<-EOWARNING.gsub(/^\s+/, '')
            Called '#{method}' without the :safe option -- defaulting to #{safe_mode} mode.
            You can avoid this warning in the future by setting the SafeYAML::OPTIONS[:default_mode] option (to :safe or :unsafe).
          EOWARNING

          SafeYAML::OPTIONS[:suppress_warnings] = true
        end

        return safe_mode
      end

      options[:safe] ? :safe : :unsafe
    end

    def options_for_safe_load(base_options)
      options = base_options.dup
      options.delete(:safe)
      options
    end
  end
end
