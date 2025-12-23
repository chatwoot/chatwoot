require 'brakeman/checks/check_cross_site_scripting'

#Checks for calls to link_to in versions of Ruby where link_to did not
#escape the first argument.
#
#See https://rails.lighthouseapp.com/projects/8994/tickets/3518-link_to-doesnt-escape-its-input
class Brakeman::CheckLinkTo < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  @description = "Checks for XSS in link_to in versions before 3.0"

  def run_check
    return unless version_between?("2.0.0", "2.9.9") and not tracker.config.escape_html?

    @ignore_methods = Set[:button_to, :check_box, :escapeHTML, :escape_once,
                           :field_field, :fields_for, :h, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :mail_to, :radio_button, :select,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :u, :url_for,
                           :will_paginate].merge tracker.options[:safe_methods]

    @known_dangerous = []
    #Ideally, I think this should also check to see if people are setting
    #:escape => false
    @models = tracker.models.keys
    @inspect_arguments = tracker.options[:check_arguments]

    tracker.find_call(:target => false, :method => :link_to).each {|call| process_result call}
  end

  def process_result result
    return if duplicate? result

    #Have to make a copy of this, otherwise it will be changed to
    #an ignored method call by the code above.
    call = result[:call]

    first_arg = call.first_arg
    second_arg = call.second_arg

    @matched = false

    #Skip if no arguments(?) or first argument is a hash
    return if first_arg.nil? or hash? first_arg

    if version_between? "2.0.0", "2.2.99"
      check_argument result, first_arg

      if second_arg and not hash? second_arg
        check_argument result, second_arg
      end
    elsif second_arg
      #Only check first argument if there is a second argument
      #in Rails 2.3.x
      check_argument result, first_arg
    end
  end

  # Check the argument for possible xss exploits
  def check_argument result, exp
    argument = process(exp)
    !check_user_input(result, argument) && !check_method(result, argument) && !check_matched(result, @matched)
  end

  # Check we should warn about the user input
  def check_user_input(result, argument)
    input = has_immediate_user_input?(argument)
    return false unless input

    message = msg("Unescaped ", msg_input(input), " in ", msg_code("link_to"))

    warn_xss(result, message, input, :high)
  end

  # Check if we should warn about the specified method
  def check_method(result, argument)
    return false if tracker.options[:ignore_model_output]
    match = has_immediate_model?(argument)
    return false unless match
    method = match.method
    return false if IGNORE_MODEL_METHODS.include? method

    confidence = :medium
    confidence = :high if likely_model_attribute? match
    warn_xss(result, msg("Unescaped model attribute in ", msg_code("link_to")), match, confidence)
  end

  # Check if we should warn about the matched result
  def check_matched(result, matched = nil)
    return false unless matched
    return false if matched.type == :model and tracker.options[:ignore_model_output]

    message = msg("Unescaped ", msg_input(matched), " in ", msg_code("link_to"))

    warn_xss(result, message, @matched, :medium)
  end

  # Create a warn for this xss
  def warn_xss(result, message, user_input, confidence)
    add_result(result)
    warn :result => result,
      :warning_type => "Cross-Site Scripting",
      :warning_code => :xss_link_to,
      :message => message,
      :user_input => user_input,
      :confidence => confidence,
      :link_path => "link_to",
      :cwe_id => [79]

    true
  end

  def process_call exp
    @mark = true
    actually_process_call exp
    exp
  end

  def actually_process_call exp
    return if @matched

    target = exp.target
    target = process target.dup if sexp? target

    #Bare records create links to the model resource,
    #not a string that could have injection
    #TODO: Needs test? I think this is broken?
    return exp if model_name? target and context == [:call, :arglist]

    super
  end
end
