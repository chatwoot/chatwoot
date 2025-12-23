require 'brakeman/checks/base_check'

class Brakeman::CheckVerbConfusion < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for uses of `request.get?` that might have unintentional behavior"

  #Process calls
  def run_check
    calls = tracker.find_call(target: :request, methods: [:get?])

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    @current_result = result
    @matched_call = result[:call]
    klass = tracker.find_class(result[:location][:class])

    # TODO: abstract into tracker.find_location ?
    if klass.nil?
      Brakeman.debug "No class found: #{result[:location][:class]}"
      return
    end

    method = klass.get_method(result[:location][:method])

    if method.nil?
      Brakeman.debug "No method found: #{result[:location][:method]}"
      return
    end

    process method.src
  end

  def process_if exp
    if exp.condition == @matched_call
      # Found `if request.get?`

      # Do not warn if there is an `elsif` clause
      if node_type? exp.else_clause, :if
        return exp
      end

      warn_about_result @current_result, exp
    end

    exp
  end

  def warn_about_result result, code
    return unless original? result

    confidence = :weak
    message = msg('Potential HTTP verb confusion. ',
                  msg_code('HEAD'),
                  ' is routed like ',
                  msg_code('GET'),
                  ' but ',
                  msg_code('request.get?'),
                  ' will return ',
                  msg_code('false')
                 )

    warn :result => result,
      :warning_type => "HTTP Verb Confusion",
      :warning_code => :http_verb_confusion,
      :message => message,
      :code => code,
      :user_input => result[:call],
      :confidence => confidence,
      :cwe_id => [352]
  end
end
