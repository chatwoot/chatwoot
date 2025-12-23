require 'brakeman/checks/base_check'

#Checks if default routes are allowed in routes.rb
class Brakeman::CheckDefaultRoutes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for default routes"

  def initialize *args
    super
    @actions_allowed_on_controller = nil
  end

  #Checks for :allow_all_actions globally and for individual routes
  #if it is not enabled globally.
  def run_check
    check_for_default_routes
    check_for_action_globs
    check_for_cve_2014_0130
  end

  def check_for_default_routes
    if allow_all_actions?
      #Default routes are enabled globally
      warn :warning_type => "Default Routes",
        :warning_code => :all_default_routes,
        :message => msg("All public methods in controllers are available as actions in ", msg_file("routes.rb")),
        :line => tracker.routes[:allow_all_actions].line,
        :confidence => :high,
        :file => "#{tracker.app_path}/config/routes.rb",
        :cwe_id => [22]
    end
  end

  def check_for_action_globs
    return if allow_all_actions?
    Brakeman.debug "Checking each controller for default routes"

    tracker.routes.each do |name, actions|
      if actions.is_a? Array and actions[0] == :allow_all_actions
        @actions_allowed_on_controller = true
        if actions[1].is_a? Hash and actions[1][:allow_verb]
          verb = actions[1][:allow_verb]
        else
          verb = "any"
        end
        warn :controller => name,
          :warning_type => "Default Routes",
          :warning_code => :controller_default_routes,
          :message => msg("Any public method in ", msg_code(name), " can be used as an action for ", msg_code(verb), " requests."),
          :line => actions[2],
          :confidence => :medium,
          :file => "#{tracker.app_path}/config/routes.rb",
          :cwe_id => [22]
      end
    end
  end

  def check_for_cve_2014_0130
    case
    when lts_version?("2.3.18.9")
      #TODO: Should support LTS 3.0.20 too
      return
    when version_between?("2.0.0", "2.3.18")
      upgrade = "3.2.18"
    when version_between?("3.0.0", "3.2.17")
      upgrade = "3.2.18"
    when version_between?("4.0.0", "4.0.4")
      upgrade = "4.0.5"
    when version_between?("4.1.0", "4.1.0")
      upgrade = "4.1.1"
    else
      return
    end

    if allow_all_actions? or @actions_allowed_on_controller
      confidence = :high
    else
      confidence = :medium
    end

    warn :warning_type => "Remote Code Execution",
      :warning_code => :CVE_2014_0130,
      :message => msg(msg_version(rails_version), " with globbing routes is vulnerable to directory traversal and remote code execution. Patch or upgrade to ", msg_version(upgrade)),
      :confidence => confidence,
      :file => "#{tracker.app_path}/config/routes.rb",
      :link => "http://matasano.com/research/AnatomyOfRailsVuln-CVE-2014-0130.pdf",
      :cwe_id => [22]
  end

  def allow_all_actions?
    tracker.routes[:allow_all_actions]
  end
end
