require 'brakeman/checks/base_check'

class Brakeman::CheckNumberToCurrency < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for number helpers XSS vulnerabilities in certain versions"

  def initialize(*)
    super
    @found_any = false
  end

  def run_check
    if version_between? "2.0.0", "2.3.18" or
      version_between? "3.0.0", "3.2.16" or
      version_between? "4.0.0", "4.0.2"

      return if lts_version? "2.3.18.8"

      check_number_helper_usage
      generic_warning unless @found_any
    end
  end

  def generic_warning
    message = msg(msg_version(rails_version), " has a vulnerability in number helpers ", msg_cve("CVE-2014-0081"), ". Upgrade to ")

    if version_between? "2.3.0", "3.2.16"
      message << msg_version("3.2.17")
    else
      message << msg_version("4.0.3")
    end

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2014_0081,
      :message => message,
      :confidence => :medium,
      :gem_info => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/msg/ruby-security-ann/9WiRn2nhfq0/2K2KRB4LwCMJ",
      :cwe_id => [79]
  end

  def check_number_helper_usage
    number_methods = [:number_to_currency, :number_to_percentage, :number_to_human]
    tracker.find_call(:target => false, :methods => number_methods).each do |result|
      arg = result[:call].second_arg
      next unless arg

      if not check_helper_option(result, arg) and hash? arg
        hash_iterate(arg) do |_key, value|
          break if check_helper_option(result, value)
        end
      end
    end
  end

  def check_helper_option result, exp
    if match = (has_immediate_user_input? exp or has_immediate_model? exp)
      warn_on_number_helper result, match
      @found_any = true
    else
      false
    end
  end

  def warn_on_number_helper result, match
    warn :result => result,
      :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2014_0081_call,
      :message => msg("Format options in ", msg_code(result[:call].method), " are not safe in ", msg_version(rails_version)),
      :confidence => :high,
      :link_path => "https://groups.google.com/d/msg/ruby-security-ann/9WiRn2nhfq0/2K2KRB4LwCMJ",
      :user_input => match,
      :cwe_id => [79]
  end
end
