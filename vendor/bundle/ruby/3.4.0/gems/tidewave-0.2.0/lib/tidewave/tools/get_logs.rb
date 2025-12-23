# frozen_string_literal: true

class Tidewave::Tools::GetLogs < Tidewave::Tools::Base
  tool_name "get_logs"
  description <<~DESCRIPTION
    Returns all log output, excluding logs that were caused by other tool calls.

    Use this tool to check for request logs or potentially logged errors.
  DESCRIPTION

  arguments do
    required(:tail).filled(:integer).description("The number of log entries to return from the end of the log")
  end

  def call(tail:)
    log_file = Rails.root.join("log", "#{Rails.env}.log")
    return "Log file not found" unless File.exist?(log_file)

    logs = File.readlines(log_file).last(tail)
    logs.join
  end
end
