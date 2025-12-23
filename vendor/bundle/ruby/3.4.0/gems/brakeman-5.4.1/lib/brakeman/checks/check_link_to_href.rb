require 'brakeman/checks/check_cross_site_scripting'

#Checks for calls to link_to which pass in potentially hazardous data
#to the second argument.  While this argument must be html_safe to not break
#the html, it must also be url safe as determined by calling a
#:url_safe_method.  This prevents attacks such as javascript:evil() or
#data:<encoded XSS> which is html_safe, but not safe as an href
#Props to Nick Green for the idea.
class Brakeman::CheckLinkToHref < Brakeman::CheckLinkTo
  Brakeman::Checks.add self

  @description = "Checks to see if values used for hrefs are sanitized using a :url_safe_method to protect against javascript:/data: XSS"

  def run_check
    @ignore_methods = Set[:button_to, :check_box,
                           :field_field, :fields_for, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :mail_to, :polymorphic_url, :radio_button, :select, :slice,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :u,
                           :will_paginate].merge(tracker.options[:url_safe_methods] || [])

    @models = tracker.models.keys
    @inspect_arguments = tracker.options[:check_arguments]

    methods = tracker.find_call :target => false, :method => :link_to
    methods.each do |call|
      process_result call
    end
  end

  def process_result result
    call = result[:call]
    @matched = false

    url_arg = if result[:block]
                process call.first_arg
              else
                process call.second_arg
              end

    if check_argument? url_arg
      url_arg = url_arg.first_arg
    end

    return if call? url_arg and ignore_call? url_arg.target, url_arg.method

    if input = has_immediate_user_input?(url_arg)
      message = msg("Unsafe ", msg_input(input), " in ", msg_code("link_to"), " href")

      unless duplicate? result or call_on_params? url_arg or ignore_interpolation? url_arg, input.match
        add_result result
        warn :result => result,
          :warning_type => "Cross-Site Scripting",
          :warning_code => :xss_link_to_href,
          :message => message,
          :user_input => input,
          :confidence => :high,
          :link_path => "link_to_href",
          :cwe_id => [79]
      end
    elsif not tracker.options[:ignore_model_output] and input = has_immediate_model?(url_arg)
      return if ignore_model_call? url_arg, input or duplicate? result
      add_result result

      message = msg("Potentially unsafe model attribute in ", msg_code("link_to"), " href")

      warn :result => result,
        :warning_type => "Cross-Site Scripting",
        :warning_code => :xss_link_to_href,
        :message => message,
        :user_input => input,
        :confidence => :weak,
        :link_path => "link_to_href",
        :cwe_id => [79]
    end
  end

  CHECK_INSIDE_METHODS = [:url_for, :h, :sanitize]

  def check_argument? url_arg
    return unless call? url_arg

    target = url_arg.target
    method = url_arg.method

    CHECK_INSIDE_METHODS.include? method or
      cgi_escaped? target, method
  end

  def ignore_model_call? url_arg, exp
    return true unless call? exp

    target = exp.target
    method = exp.method

    return true unless model_find_call? target

    return true unless method.to_s =~ /url|uri|link|page|site/

    ignore_call? target, method or
      IGNORE_MODEL_METHODS.include? method or
      ignore_interpolation? url_arg, exp
  end

  #Ignore situations where the href is an interpolated string
  #with something before the user input
  def ignore_interpolation? arg, suspect
    return unless string_interp? arg
    return true unless arg[1].chomp.empty? # plain string before interpolation

    first_interp = arg.find_nodes(:evstr).first
    return unless first_interp

    first_interp[1].deep_each do |e|
      if suspect == e
        return false
      end
    end

    true
  end

  def ignore_call? target, method
    decorated_model? method or super
  end

  def decorated_model? method
    tracker.config.has_gem? :draper and
      method == :decorate
  end

  def ignored_method? target, method
    @ignore_methods.include? method or
      method.to_s =~ /_path$/ or
      (target.nil? and method.to_s =~ /_url$/)
  end

  def model_find_call? exp
    return unless call? exp

    MODEL_METHODS.include? exp.method or
      exp.method.to_s =~ /^find_by_/
  end

  def call_on_params? exp
    call? exp and
    params? exp.target and
    exp.method != :[]
  end
end
