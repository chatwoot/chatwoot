require 'brakeman/checks/check_file_access'
require 'brakeman/processors/lib/processor_helper'

#Checks for user input in send_file()
class Brakeman::CheckSendFile < Brakeman::CheckFileAccess
  Brakeman::Checks.add self

  @description = "Check for user input in uses of send_file"

  def run_check
    Brakeman.debug "Finding all calls to send_file()"

    methods = tracker.find_call :target => false, :method => :send_file

    methods.each do |call|
      process_result call
    end
  end
end
