require 'brakeman/checks/base_check'

class Brakeman::CheckSanitizeConfigCve < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for vunerable uses of sanitize (CVE-2022-32209)"

  def run_check
    @specific_warning = false

    @gem_version = tracker.config.gem_version :'rails-html-sanitizer'
    if version_between? "0.0.0", "1.4.2", @gem_version
      check_config
      check_sanitize_calls
      check_safe_list_allowed_tags

      unless @specific_warning
        # General warning about the vulnerable version
        cve_warning
      end
    end
  end

  def cve_warning confidence: :weak, result: nil
    return if result and not original? result

    message = msg(msg_version(@gem_version, 'rails-html-sanitizer'),
                  " is vulnerable to cross-site scripting when ",
                  msg_code('select'),
                  " and ",
                  msg_code("style"),
                  " tags are allowed ",
                  msg_cve("CVE-2022-32209")
                 )

    unless result
      message << ". Upgrade to 1.4.3 or newer"
    end

    warn :warning_type => "Cross-Site Scripting",
      :warning_code => :CVE_2022_32209,
      :message => message,
      :confidence => confidence,
      :gem_info => gemfile_or_environment(:'rails-html-sanitizer'),
      :link_path => "https://groups.google.com/g/rubyonrails-security/c/ce9PhUANQ6s/m/S0fJfnkmBAAJ",
      :cwe_id => [79],
      :result => result
  end

  # Look for
  #   config.action_view.sanitized_allowed_tags = ["select", "style"]
  def check_config
    sanitizer_config = tracker.config.rails.dig(:action_view, :sanitized_allowed_tags)

    if sanitizer_config and include_both_tags? sanitizer_config
      @specific_warning = true
      cve_warning confidence: :high
    end
  end

  # Look for
  #   sanitize ..., tags: ["select", "style"]
  # and
  #   Rails::Html::SafeListSanitizer.new.sanitize(..., tags: ["select", "style"])
  def check_sanitize_calls
    tracker.find_call(method: :sanitize, target: nil).each do |result|
      check_tags_option result
    end

    tracker.find_call(method: :sanitize, target: :'Rails::Html::SafeListSanitizer.new').each do |result|
      check_tags_option result
    end
  end

  # Look for
  #   Rails::Html::SafeListSanitizer.allowed_tags = ["select", "style"]
  def check_safe_list_allowed_tags
    tracker.find_call(target: :'Rails::Html::SafeListSanitizer', method: :allowed_tags=).each do |result|
      check_result result, result[:call].first_arg
    end
  end

  private

  def check_tags_option result
    options = result[:call].last_arg

    if options
      check_result result, hash_access(options, :tags)
    end
  end

  def check_result result, arg
    if include_both_tags? arg
      @specific_warning = true
      cve_warning confidence: :high, result: result
    end
  end

  def include_both_tags? exp
    return unless sexp? exp

    has_tag? exp, 'select' and
      has_tag? exp, 'style'
  end

  def has_tag? exp, tag
    tag_sym = tag.to_sym

    exp.each_sexp do |e|
      if string? e and e.value == tag
        return true
      elsif symbol? e and e.value == tag_sym
        return true
      end
    end

    false
  end
end
