# frozen_string_literal: true

require "timeout"
require "json"

class Tidewave::Tools::ProjectEval < Tidewave::Tools::Base
  tool_name "project_eval"
  description <<~DESCRIPTION
    Evaluates Ruby code in the context of the project.

    The current Ruby version is: #{RUBY_VERSION}

    Use this tool every time you need to evaluate Ruby code,
    including to test the behaviour of a function or to debug
    something. The tool also returns anything written to standard
    output. DO NOT use shell tools to evaluate Ruby code.
  DESCRIPTION

  arguments do
    required(:code).filled(:string).description("The Ruby code to evaluate")
    optional(:arguments).value(:array).description("The arguments to pass to evaluation. They are available inside the evaluated code as `arguments`.")
    optional(:timeout).filled(:integer).description("The timeout in milliseconds. If the evaluation takes longer than this, it will be terminated. Defaults to 30000 (30 seconds).")
    optional(:json).filled(:bool).description("Whether to return the result as JSON with structured output containing result, success, stdout, and stderr fields. Defaults to false.")
  end

  def call(code:, arguments: [], timeout: 30_000, json: false)
    original_stdout = $stdout
    original_stderr = $stderr

    stdout_capture = StringIO.new
    stderr_capture = StringIO.new
    $stdout = stdout_capture
    $stderr = stderr_capture

    begin
      timeout_seconds = timeout / 1000.0

      success, result = begin
        Timeout.timeout(timeout_seconds) do
          [ true, eval(code, eval_binding(arguments)) ]
        end
      rescue Timeout::Error
        [ false, "Timeout::Error: Evaluation timed out after #{timeout} milliseconds." ]
      rescue => e
        [ false, e.full_message ]
      end

      stdout = stdout_capture.string
      stderr = stderr_capture.string

      if json
        JSON.generate({
          result: result,
          success: success,
          stdout: stdout,
          stderr: stderr
        })
      elsif stdout.empty? && stderr.empty?
        # We explicitly call to_s so the result is not accidentally
        # parsed as a JSON response by FastMCP.
        result.to_s
      else
        <<~OUTPUT
          STDOUT:

          #{stdout}

          STDERR:

          #{stderr}

          Result:

          #{result}
        OUTPUT
      end
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end

  private

  def eval_binding(arguments)
    binding
  end
end
