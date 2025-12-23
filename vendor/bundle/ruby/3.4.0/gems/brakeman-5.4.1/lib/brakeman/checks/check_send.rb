require 'brakeman/checks/base_check'

#Checks if user supplied data is passed to send
class Brakeman::CheckSend < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for unsafe use of Object#send"

  def run_check
    @send_methods = [:send, :try, :__send__, :public_send]
    Brakeman.debug("Finding instances of #send")
    calls = tracker.find_call :methods => @send_methods, :nested => true

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    return unless original? result

    send_call = get_send result[:call]
    process_call_args send_call
    process send_call.target

    if input = has_immediate_user_input?(send_call.first_arg)
      warn :result => result,
        :warning_type => "Dangerous Send",
        :warning_code => :dangerous_send,
        :message => "User controlled method execution",
        :user_input => input,
        :confidence => :high,
        :cwe_id => [77]
    end
  end

  # Recursively check call chain for send call
  def get_send exp
    if call? exp
      if @send_methods.include? exp.method
        return exp
      else
        get_send exp.target
      end
    end
  end
end
