# frozen_string_literal: true

require "tidewave/file_tracker"

class Tidewave::Tools::ReadProjectFile < Tidewave::Tools::Base
  tags :file_system_tool

  tool_name "read_project_file"
  description <<~DESCRIPTION
    Returns the contents of the given file.
    Supports an optional line_offset and count. To read the full file, only the path needs to be passed.
  DESCRIPTION

  arguments do
    required(:path).filled(:string).description("The path to the file to read. It is relative to the project root.")
    optional(:line_offset).filled(:integer).description("Optional: the starting line offset from which to read. Defaults to 0.")
    optional(:count).filled(:integer).description("Optional: the number of lines to read. Defaults to all.")
  end

  def call(path:, **keywords)
    Tidewave::FileTracker.validate_path_access!(path)
    _meta[:mtime], contents = Tidewave::FileTracker.read_file(path, **keywords)
    contents
  end
end
