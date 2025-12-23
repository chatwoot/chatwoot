require 'brakeman/checks/base_check'

class Brakeman::CheckReverseTabnabbing < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Checks for reverse tabnabbing cases on 'link_to' calls"

  def run_check
    calls = tracker.find_call :methods => :link_to
    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    return unless original? result and result[:call].last_arg

    html_opts = result[:call].last_arg
    return unless hash? html_opts

    target = hash_access html_opts, :target
    unless target &&
          (string?(target) && target.value == "_blank" ||
          symbol?(target) && target.value == :_blank)
      return
    end

    target_url = result[:block] ? result[:call].first_arg : result[:call].second_arg

    # `url_for` and `_path` calls lead to urls on to the same origin.
    # That means that an adversary would need to run javascript on
    # the victim application's domain. If that is the case, the adversary
    # already has the ability to redirect the victim user anywhere.
    # Also statically provided URLs (interpolated or otherwise) are also
    # ignored as they produce many false positives.
    return if !call?(target_url) || target_url.method.match(/^url_for$|_path$/)

    rel = hash_access html_opts, :rel
    confidence = :medium

    if rel && string?(rel) then
      rel_opt = rel.value
      return if rel_opt.include?("noopener") && rel_opt.include?("noreferrer")

      if rel_opt.include?("noopener") ^ rel_opt.include?("noreferrer") then
        confidence = :weak
      end
    end

    warn :result => result,
      :warning_type => "Reverse Tabnabbing",
      :warning_code => :reverse_tabnabbing,
      :message => msg("When opening a link in a new tab without setting ", msg_code('rel: "noopener noreferrer"'),
                      ", the new tab can control the parent tab's location. For example, an attacker could redirect to a phishing page."),
      :confidence => confidence,
      :user_input => rel,
      :cwe_id => [1022]
  end
end
