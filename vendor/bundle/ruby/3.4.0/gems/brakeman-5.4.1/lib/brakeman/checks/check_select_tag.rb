require 'brakeman/checks/base_check'

#Checks for CVE-2012-3463, unescaped input in :prompt option of select_tag:
#https://groups.google.com/d/topic/rubyonrails-security/fV3QUToSMSw/discussion
class Brakeman::CheckSelectTag < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Looks for unsafe uses of select_tag() in some versions of Rails 3.x"

  def run_check

    if version_between? "3.0.0", "3.0.16"
      suggested_version = "3.0.17"
    elsif version_between? "3.1.0", "3.1.7"
      suggested_version = "3.1.8"
    elsif version_between? "3.2.0", "3.2.7"
      suggested_version = "3.2.8"
    else
      return
    end

    @ignore_methods = Set[:escapeHTML, :escape_once, :h].merge tracker.options[:safe_methods]

    @message = msg("Upgrade to ", msg_version(suggested_version), ". In ", msg_version(rails_version), " ", msg_code("select_tag"), " is vulnerable ", msg_cve("CVE-2012-3463"))

    calls = tracker.find_call(:target => nil, :method => :select_tag).select do |result|
      result[:location][:type] == :template
    end

    calls.each do |result|
      process_result result
    end
  end

  #Check if select_tag is called with user input in :prompt option
  def process_result result
    return unless original? result

    #Only concerned if user input is supplied for :prompt option
    last_arg = result[:call].last_arg

    if hash? last_arg
      prompt_option = hash_access last_arg, :prompt

      if call? prompt_option and @ignore_methods.include? prompt_option.method
        return
      elsif sexp? prompt_option and input = include_user_input?(prompt_option)

        warn :warning_type => "Cross-Site Scripting",
          :warning_code => :CVE_2012_3463,
          :result => result,
          :message => @message,
          :confidence => :high,
          :user_input => input,
          :link_path => "https://groups.google.com/d/topic/rubyonrails-security/fV3QUToSMSw/discussion",
          :cwe_id => [79]
      end
    end
  end
end
