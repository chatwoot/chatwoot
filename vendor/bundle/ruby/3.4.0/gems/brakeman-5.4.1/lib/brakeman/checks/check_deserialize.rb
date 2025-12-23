require 'brakeman/checks/base_check'

class Brakeman::CheckDeserialize < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unsafe deserialization of objects"

  def run_check
    check_yaml
    check_csv
    check_marshal
    check_oj
  end

  def check_yaml
    check_methods :YAML, :load_documents, :load_stream, :parse_documents, :parse_stream

    # Check for safe_yaml gem use with YAML.load(..., safe: true)
    if uses_safe_yaml?
      tracker.find_call(target: :YAML, method: :load).each do |result|
        call = result[:call]
        options = call.second_arg

        if hash? options and true? hash_access(options, :safe)
          next
        else
          check_deserialize result, :YAML
        end
      end
    else
      check_methods :YAML, :load
    end
  end

  def check_csv
    check_methods :CSV, :load
  end

  def check_marshal
    check_methods :Marshal, :load, :restore
  end

  def check_oj
    check_methods :Oj, :object_load # Always unsafe, regardless of mode

    unsafe_mode = :object
    safe_default = oj_safe_default?

    tracker.find_call(:target => :Oj, :method => :load).each do |result|
      call = result[:call]
      options = call.second_arg

      if options and hash? options and mode = hash_access(options, :mode)
        if symbol? mode and mode.value == unsafe_mode
          check_deserialize result, :Oj
        end
      elsif not safe_default
        check_deserialize result, :Oj
      end
    end
  end

  def check_methods target, *methods
    tracker.find_call(:target => target, :methods => methods ).each do |result|
      check_deserialize result, target
    end
  end

  def check_deserialize result, target, arg = nil
    return unless original? result

    arg ||= result[:call].first_arg
    method = result[:call].method

    if input = has_immediate_user_input?(arg)
      confidence = :high
    elsif input = include_user_input?(arg)
      confidence = :medium
    end

    if confidence
      message = msg(msg_code("#{target}.#{method}"), " called with ", msg_input(input))

      warn :result => result,
        :warning_type => "Remote Code Execution",
        :warning_code => :unsafe_deserialize,
        :message => message,
        :user_input => input,
        :confidence => confidence,
        :link_path => "unsafe_deserialization",
        :cwe_id => [502]
    end
  end

  private

  def oj_safe_default?
    safe_default = false

    if tracker.find_call(target: :Oj, method: :mimic_JSON).any?
      safe_default = true
    elsif result = tracker.find_call(target: :Oj, method: :default_options=).first
      options = result[:call].first_arg

      if oj_safe_mode? options
        safe_default = true
      end
    end

    safe_default
  end

  def oj_safe_mode? options
    if hash? options and mode = hash_access(options, :mode)
      if symbol? mode and mode != :object
        return true
      end
    end

    false
  end

  def uses_safe_yaml?
    tracker.config.has_gem? :safe_yaml
  end
end
