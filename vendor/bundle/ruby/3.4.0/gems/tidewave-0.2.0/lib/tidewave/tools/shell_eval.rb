# frozen_string_literal: true

require "open3"

class Tidewave::Tools::ShellEval < Tidewave::Tools::Base
  tags :file_system_tool
  class CommandFailedError < StandardError; end

  tool_name "shell_eval"
  description <<~DESCRIPTION
    Executes a shell command in the project root directory.

    The operating system is of flavor #{RUBY_PLATFORM}.

    Avoid using this tool for manipulating project files.
    Instead rely on the tools with the name matching `*_project_files`.

    Do not use this tool to evaluate Ruby code. Use `project_eval` instead.
    Do not use this tool for commands that run indefinitely,
    such as servers (like `bin/dev` or `npm run dev`),
    REPLs (`bin/rails console`) or file watchers.

    Only use this tool if other means are not available.
  DESCRIPTION

  arguments do
    required(:command).filled(:string).description("The shell command to execute. Avoid using this for file operations; use dedicated file system tools instead.")
  end

  def call(command:)
    stdout, status = Open3.capture2e(command)
    raise CommandFailedError, "Command failed with status #{status.exitstatus}:\n\n#{stdout}" unless status.exitstatus.zero?

    stdout.strip
  end
end
