# frozen_string_literal: true

require "tidewave/file_tracker"

class Tidewave::Tools::ListProjectFiles < Tidewave::Tools::Base
  tags :file_system_tool

  tool_name "list_project_files"
  description <<~DESC
    Returns a list of files in the project.

    By default, when no arguments are passed, it returns all files in the project that
    are not ignored by .gitignore.

    Optionally, a glob_pattern can be passed to filter this list.
  DESC

  arguments do
    optional(:glob_pattern).maybe(:string).description("Optional: a glob pattern to filter the listed files")
    optional(:include_ignored).maybe(:bool).description("Optional: whether to include files that are ignored by .gitignore. Defaults to false. WARNING: Use with targeted glob patterns to avoid listing excessive files from dependencies or build directories.")
  end

  def call(glob_pattern: nil, include_ignored: false)
    Tidewave::FileTracker.project_files(glob_pattern: glob_pattern, include_ignored: include_ignored)
  end
end
