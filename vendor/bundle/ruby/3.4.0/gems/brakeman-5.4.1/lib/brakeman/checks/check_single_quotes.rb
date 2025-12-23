require 'brakeman/checks/base_check'

#Checks for versions which do not escape single quotes.
#https://groups.google.com/d/topic/rubyonrails-security/kKGNeMrnmiY/discussion
class Brakeman::CheckSingleQuotes < Brakeman::BaseCheck
  Brakeman::Checks.add self
  RACK_UTILS = Sexp.new(:colon2, Sexp.new(:const, :Rack), :Utils)

  @description = "Check for versions which do not escape single quotes (CVE-2012-3464)"

  def initialize *args
    super
    @inside_erb = @inside_util = @inside_html_escape = @uses_rack_escape = false
  end

  def run_check
    return if uses_rack_escape?

    if version_between? '2.0.0', '2.3.14'
      message = msg("All Rails 2.x versions do not escape single quotes ", msg_cve("CVE-2012-3464"))
    else
      message = msg(msg_version(rails_version), " does not escape single quotes ", msg_cve("CVE-2012-3464"), ". Upgrade to ")

      case
      when version_between?('3.0.0', '3.0.16')
        message << msg_version('3.0.17')
      when version_between?('3.1.0', '3.1.7')
        message << msg_version('3.1.8')
      when version_between?('3.2.0', '3.2.7')
        message << msg_version('3.2.8')
      else
        return
      end
    end

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2012_3464,
      :message => message,
      :confidence => :medium,
      :gem_info => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/topic/rubyonrails-security/kKGNeMrnmiY/discussion",
      :cwe_id => [79]
  end

  #Process initializers to see if they use workaround
  #by replacing Erb::Util.html_escape
  def uses_rack_escape?
    @tracker.initializers.each do |_name, src|
      process src
    end

    @uses_rack_escape
  end

  #Look for
  #
  #    class ERB
  def process_class exp
    if exp.class_name == :ERB
      @inside_erb = true
      process_all exp.body
      @inside_erb = false
    end

    exp
  end

  #Look for
  #
  #    module Util
  def process_module exp
    if @inside_erb and exp.module_name == :Util
      @inside_util = true
      process_all exp.body
      @inside_util = false
    end

    exp
  end

  #Look for
  #
  #    def html_escape
  def process_defn exp
    if @inside_util and exp.method_name == :html_escape
      @inside_html_escape = true
      process_all exp.body
      @inside_html_escape = false
    end

    exp
  end

  #Look for
  #
  #    Rack::Utils.escape_html
  def process_call exp
    if @inside_html_escape and exp.target == RACK_UTILS and exp.method == :escape_html
      @uses_rack_escape = true
    else
      process exp.target if exp.target
    end

    exp
  end
end
