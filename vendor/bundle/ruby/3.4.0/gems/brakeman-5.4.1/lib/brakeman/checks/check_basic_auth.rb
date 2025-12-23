require 'brakeman/checks/base_check'

#Checks if password is stored in controller
#when using http_basic_authenticate_with
#
#Only for Rails >= 3.1
class Brakeman::CheckBasicAuth < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for the use of http_basic_authenticate_with"

  def run_check
    return if version_between? "0.0.0", "3.0.99"

    check_basic_auth_filter
    check_basic_auth_request
  end

  def check_basic_auth_filter
    controllers = tracker.controllers.select do |_name, c|
      c.options[:http_basic_authenticate_with]
    end

    Hash[controllers].each do |name, controller|
      controller.options[:http_basic_authenticate_with].each do |call|

        if pass = get_password(call) and string? pass
          warn :controller => name,
              :warning_type => "Basic Auth",
              :warning_code => :basic_auth_password,
              :message => "Basic authentication password stored in source code",
              :code => call,
              :confidence => :high,
              :file => controller.file,
              :cwe_id => [259]
          break
        end
      end
    end
  end

  # Look for
  #  authenticate_or_request_with_http_basic do |username, password|
  #    username == "foo" && password == "bar"
  #  end
  def check_basic_auth_request
    tracker.find_call(:target => nil, :method => :authenticate_or_request_with_http_basic).each do |result|
      if include_password_literal? result
          warn :result => result,
              :code => @include_password,
              :warning_type => "Basic Auth",
              :warning_code => :basic_auth_password,
              :message => "Basic authentication password stored in source code",
              :confidence => :high,
              :cwe_id => [259]
      end
    end
  end

  # Check if the block of a result contains a comparison of password to string
  def include_password_literal? result
    return false if result[:block_args].nil?

    @password_var = result[:block_args].last
    @include_password = false
    process result[:block]
    @include_password
  end

  # Looks for :== calls on password var
  def process_call exp
    target = exp.target

    if node_type?(target, :lvar) and
      target.value == @password_var and
      exp.method == :== and
      string? exp.first_arg

      @include_password = exp
    end

    exp
  end

  def get_password call
    arg = call.first_arg

    return false if arg.nil? or not hash? arg

    hash_access(arg, :password)
  end
end
