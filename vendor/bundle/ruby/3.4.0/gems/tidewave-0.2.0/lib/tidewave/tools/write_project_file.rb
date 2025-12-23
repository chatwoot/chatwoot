# frozen_string_literal: true

require "tidewave/file_tracker"

class Tidewave::Tools::WriteProjectFile < Tidewave::Tools::Base
  tags :file_system_tool

  tool_name "write_project_file"
  description <<~DESCRIPTION
    Writes a file to the file system. If the file already exists, it will be overwritten.

    Note that this tool will fail if the file wasn't previously read with the `read_project_file` tool.
  DESCRIPTION

  arguments do
    required(:path).filled(:string).description("The path to the file to write. It is relative to the project root.")
    required(:content).filled(:string).description("The content to write to the file")
    optional(:atime).filled(:integer).hidden.description("The Unix timestamp this file was last accessed. Not to be used.")
  end

  def call(path:, content:, atime: nil)
    Tidewave::FileTracker.validate_path_is_writable!(path, atime)
    Tidewave::FileTracker.write_file(path, content)
    _meta[:mtime] = Time.now.to_i

    "OK"
  end
end
