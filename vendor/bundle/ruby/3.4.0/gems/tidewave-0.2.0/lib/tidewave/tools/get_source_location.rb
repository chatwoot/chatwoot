# frozen_string_literal: true

class Tidewave::Tools::GetSourceLocation < Tidewave::Tools::Base
  tool_name "get_source_location"

  description <<~DESCRIPTION
    Returns the source location for the given reference.

    The reference may be a constant, most commonly classes and modules
    such as `String`, an instance method, such as `String#gsub`, or class
    method, such as `File.executable?`

    This works for methods in the current project, as well as dependencies.

    This tool only works if you know the specific constant/method being targeted.
    If that is the case, prefer this tool over grepping the file system.
  DESCRIPTION

  arguments do
    required(:reference).filled(:string).description("The constant/method to lookup, such String, String#gsub or File.executable?")
  end

  def call(reference:)
    file_path, line_number = self.class.get_source_location(reference)

    if file_path
      begin
        relative_path = Pathname.new(file_path).relative_path_from(Rails.root)
        "#{relative_path}:#{line_number}"
      rescue ArgumentError
        # If the path cannot be made relative, return the absolute path
        "#{file_path}:#{line_number}"
      end
    else
      raise NameError, "could not find source location for #{reference}"
    end
  end

  def self.get_source_location(reference)
    constant_path, selector, method_name = reference.rpartition(/\.|#/)

    # There are no selectors, so the method_name is a constant path
    return Object.const_source_location(method_name) if selector.empty?

    begin
      mod = Object.const_get(constant_path)
    rescue NameError => e
      raise e
    rescue
      raise "wrong or invalid reference #{reference}"
    end

    raise "reference #{constant_path} does not point a class/module" unless mod.is_a?(Module)

    if selector == "#"
      mod.instance_method(method_name).source_location
    else
      mod.method(method_name).source_location
    end
  end
end
