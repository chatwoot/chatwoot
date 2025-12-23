require 'brakeman/checks/base_check'

class Brakeman::CheckDivideByZero < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Warns on potential division by zero"

  def run_check
    tracker.find_call(:method => :"/").each do |result|
      check_division result
    end
  end

  def check_division result
    return unless original? result

    call = result[:call]

    denominator = call.first_arg

    if number? denominator and denominator.value == 0
      numerator = call.target

      if number? numerator
        if numerator.value.is_a? Float
          return # 0.0 / 0 is NaN and 1.0 / 0 is Infinity
        else
          confidence = :medium
        end
      else
        confidence = :weak
      end

      warn :result => result,
        :warning_type => "Divide by Zero",
        :warning_code => :divide_by_zero,
        :message => "Potential division by zero",
        :confidence => confidence,
        :user_input => denominator,
        :cwe_id => [369]
    end
  end
end
