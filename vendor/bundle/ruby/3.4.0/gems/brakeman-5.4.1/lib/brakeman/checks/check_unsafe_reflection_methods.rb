require 'brakeman/checks/base_check'

class Brakeman::CheckUnsafeReflectionMethods < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unsafe reflection to access methods"

  def run_check
    check_method
    check_tap
    check_to_proc
  end

  def check_method
    tracker.find_call(method: :method, nested: true).each do |result|
      argument = result[:call].first_arg

      if user_input = include_user_input?(argument)
        warn_unsafe_reflection(result, user_input)
      end
    end
  end

  def check_tap
    tracker.find_call(method: :tap, nested: true).each do |result|
      argument = result[:call].first_arg

      # Argument is passed like a.tap(&argument)
      if node_type? argument, :block_pass
        argument = argument.value
      end

      if user_input = include_user_input?(argument)
        warn_unsafe_reflection(result, user_input)
      end
    end
  end

  def check_to_proc
    tracker.find_call(method: :to_proc, nested: true).each do |result|
      target = result[:call].target

      if user_input = include_user_input?(target)
        warn_unsafe_reflection(result, user_input)
      end
    end
  end

  def warn_unsafe_reflection result, input
    return unless original? result
    method = result[:call].method

    confidence = if input.type == :params
      :high
    else
      :medium
    end

    message = msg("Unsafe reflection method ", msg_code(method), " called with ", msg_input(input))

    warn :result => result,
      :warning_type => "Remote Code Execution",
      :warning_code => :unsafe_method_reflection,
      :message => message,
      :user_input => input,
      :confidence => confidence,
      :cwe_id => [470]
  end
end
