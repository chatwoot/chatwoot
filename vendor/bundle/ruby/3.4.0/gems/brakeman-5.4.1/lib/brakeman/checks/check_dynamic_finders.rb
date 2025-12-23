require 'brakeman/checks/base_check'

#This check looks for regexes that include user input.
class Brakeman::CheckDynamicFinders < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check unsafe usage of find_by_*"

  def run_check
    if tracker.config.has_gem? :mysql and version_between? '2.0.0', '4.1.99'
      tracker.find_call(:method => /^find_by_/).each do |result|
        process_result result
      end
    end
  end

  def process_result result
    return unless original? result

    call = result[:call]

    if potentially_dangerous? call.method
      call.each_arg do |arg|
        if params? arg and not safe_call? arg
          warn :result => result,
            :warning_type => "SQL Injection",
            :warning_code => :sql_injection_dynamic_finder,
            :message => "MySQL integer conversion may cause 0 to match any string",
            :confidence => :medium,
            :user_input => arg,
            :cwe_id => [89]

          break
        end
      end
    end
  end

  def safe_call? arg
    return false unless call? arg

    meth = arg.method
    meth == :to_s or meth == :to_i
  end

  def potentially_dangerous? method_name
    method_name.match(/^find_by_.*(token|guid|password|api_key|activation|code|private|reset)/)
  end
end
