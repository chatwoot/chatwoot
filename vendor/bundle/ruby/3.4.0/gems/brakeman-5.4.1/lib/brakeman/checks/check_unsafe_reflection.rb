require 'brakeman/checks/base_check'

# Checks for string interpolation and parameters in calls to
# String#constantize, String#safe_constantize, Module#const_get and Module#qualified_const_get.
#
# Exploit examples at: http://blog.conviso.com.br/exploiting-unsafe-reflection-in-rubyrails-applications/
class Brakeman::CheckUnsafeReflection < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unsafe reflection"

  def run_check
    reflection_methods = [:constantize, :safe_constantize, :const_get, :qualified_const_get]

    tracker.find_call(:methods => reflection_methods, :nested => true).each do |result|
      check_unsafe_reflection result
    end
  end

  def check_unsafe_reflection result
    return unless original? result

    call = result[:call]
    method = call.method

    case method
    when :constantize, :safe_constantize
      arg = call.target
    else
      arg = call.first_arg
    end

    if input = has_immediate_user_input?(arg)
      confidence = :high
    elsif input = include_user_input?(arg)
      confidence = :medium
    end

    if confidence
      case method
      when :constantize, :safe_constantize
        message = msg("Unsafe reflection method ", msg_code(method), " called on ", msg_input(input))
      else
        message = msg("Unsafe reflection method ", msg_code(method), " called with ", msg_input(input))
      end

      warn :result => result,
        :warning_type => "Remote Code Execution",
        :warning_code => :unsafe_constantize,
        :message => message,
        :user_input => input,
        :confidence => confidence,
        :cwe_id => [470]
    end
  end
end
