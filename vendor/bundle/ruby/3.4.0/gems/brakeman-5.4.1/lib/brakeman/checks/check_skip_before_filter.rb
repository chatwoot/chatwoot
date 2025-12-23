require 'brakeman/checks/base_check'

#At the moment, this looks for
#
#  skip_before_filter :verify_authenticity_token, :except => [...]
#
#which is essentially a skip-by-default approach (no actions are checked EXCEPT the
#ones listed) versus a enforce-by-default approach (ONLY the actions listed will skip
#the check)
class Brakeman::CheckSkipBeforeFilter < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Warn when skipping CSRF or authentication checks by default"

  def run_check
    tracker.controllers.each do |_name, controller|
      controller.skip_filters.each do |filter|
        process_skip_filter filter, controller
      end
    end
  end

  def process_skip_filter filter, controller
    case skip_except_value filter
    when :verify_authenticity_token
      warn :class => controller.name, #ugh this should be a controller warning, too
        :warning_type => "Cross-Site Request Forgery",
        :warning_code => :csrf_blacklist,
        :message => msg("List specific actions (", msg_code(":only => [..]"), ") when skipping CSRF check"),
        :code => filter,
        :confidence => :medium,
        :file => controller.file,
        :cwe_id => [352]

    when :login_required, :authenticate_user!, :require_user
      warn :controller => controller.name,
        :warning_code => :auth_blacklist,
        :warning_type => "Authentication",
        :message => msg("List specific actions (", msg_code(":only => [..]"), ") when skipping authentication"),
        :code => filter,
        :confidence => :medium,
        :link_path => "authentication_whitelist",
        :file => controller.file,
        :cwe_id => [287]
    end
  end

  def skip_except_value filter
    return false unless call? filter

    first_arg = filter.first_arg
    last_arg = filter.last_arg

    if symbol? first_arg and hash? last_arg
      if hash_access(last_arg, :except)
        return first_arg.value
      end
    end

    false
  end
end
