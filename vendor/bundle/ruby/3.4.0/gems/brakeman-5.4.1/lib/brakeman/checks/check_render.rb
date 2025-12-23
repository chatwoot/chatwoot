require 'brakeman/checks/base_check'

#Check calls to +render()+ for dangerous values
class Brakeman::CheckRender < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds calls to render that might allow file access or code execution"

  def run_check
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render_result result
    end
  end

  def process_render_result result
    return unless node_type? result[:call], :render

    case result[:call].render_type
    when :partial, :template, :action, :file
      check_for_rce(result) or
        check_for_dynamic_path(result)
    when :inline
    when :js
    when :json
    when :text
    when :update
    when :xml
    end
  end

  #Check if path to action or file is determined dynamically
  def check_for_dynamic_path result
    view = result[:call][2]

    if sexp? view and original? result
      return if renderable?(view)

      if input = has_immediate_user_input?(view)
        if string_interp? view
          confidence = :medium
        else
          confidence = :high
        end
      elsif input = include_user_input?(view)
        confidence = :weak
      else
        return
      end

      return if input.type == :model #skip models
      return if safe_param? input.match

      message = msg("Render path contains ", msg_input(input))

      warn :result => result,
        :warning_type => "Dynamic Render Path",
        :warning_code => :dynamic_render_path,
        :message => message,
        :user_input => input,
        :confidence => confidence,
        :cwe_id => [22]
    end
  end

  def check_for_rce result
    return unless version_between? "0.0.0", "3.2.22" or
                  version_between? "4.0.0", "4.1.14" or
                  version_between? "4.2.0", "4.2.5"


    view = result[:call][2]
    if sexp? view and not duplicate? result
      if params? view
        add_result result
        return if safe_param? view

        warn :result => result,
          :warning_type => "Remote Code Execution",
          :warning_code => :dynamic_render_path_rce,
          :message => msg("Passing query parameters to ", msg_code("render"), " is vulnerable in ", msg_version(rails_version), " ", msg_cve("CVE-2016-0752")),
          :user_input => view,
          :confidence => :high,
          :cwe_id => [22]
      end
    end
  end

  def safe_param? exp
    if params? exp and call? exp
      method_name = exp.method

      if method_name == :[]
        arg = exp.first_arg
        symbol? arg and [:controller, :action].include? arg.value
      else
        boolean_method? method_name
      end
    end
  end

  def renderable? exp
    return false unless call?(exp) and constant?(exp.target)

    target_class_name = class_name(exp.target)
    known_renderable_class?(target_class_name) or tracker.find_method(:render_in, target_class_name)
  end

  def known_renderable_class? class_name
    klass = tracker.find_class(class_name)
    return false if klass.nil?
    klass.ancestor? :"ViewComponent::Base"
  end
end
