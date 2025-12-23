require 'brakeman/checks/base_check'

class Brakeman::CheckCreateWith < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for strong params bypass in CVE-2014-3514"

  def run_check
    @warned = false

    if version_between? "4.0.0", "4.0.8"
      suggested_version = "4.0.9"
    elsif version_between? "4.1.0", "4.1.4"
      suggested_version = "4.1.5"
    else
      return
    end

    @message = msg(msg_code("create_with"), " is vulnerable to strong params bypass. Upgrade to ", msg_version(suggested_version), " or patch")

    tracker.find_call(:method => :create_with, :nested => true).each do |result|
      process_result result
    end

    generic_warning unless @warned
  end

  def process_result result
    return unless original? result
    arg = result[:call].first_arg

    confidence = danger_level arg

    if confidence
      @warned = true

      warn :warning_type => "Mass Assignment",
        :warning_code => :CVE_2014_3514_call,
        :result => result,
        :message => @message,
        :confidence => confidence,
        :link_path => "https://groups.google.com/d/msg/rubyonrails-security/M4chq5Sb540/CC1Fh0Y_NWwJ",
        :cwe_id => [915]
    end
  end

  #For a given create_with call, set confidence level.
  #Ignore calls that use permit()
  def danger_level exp
    return unless sexp? exp

    if call? exp and exp.method == :permit
      nil
    elsif request_value? exp
      :high
    elsif hash? exp
      nil
    elsif has_immediate_user_input?(exp)
      :high
    elsif include_user_input? exp
      :medium
    else
      :weak
    end
  end

  def generic_warning
      warn :warning_type => "Mass Assignment",
        :warning_code => :CVE_2014_3514,
        :message => @message,
        :gem_info => gemfile_or_environment,
        :confidence => :medium,
        :link_path => "https://groups.google.com/d/msg/rubyonrails-security/M4chq5Sb540/CC1Fh0Y_NWwJ",
        :cwe_id => [915]
  end
end
