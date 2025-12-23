require 'brakeman/checks/base_check'

class Brakeman::CheckJSONEntityEscape < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check if HTML escaping is disabled for JSON output"

  def run_check
    check_config_setting
    check_manual_disable
  end

  def check_config_setting
    if false? tracker.config.rails.dig(:active_support, :escape_html_entities_in_json)
      warn :warning_type => "Cross-Site Scripting",
        :warning_code => :json_html_escape_config,
        :message => msg("HTML entities in JSON are not escaped by default"),
        :confidence => :medium,
        :file => "config/environments/production.rb",
        :line => 1,
        :cwe_id => [79]
    end
  end

  def check_manual_disable
    tracker.find_call(targets: [:ActiveSupport, :'ActiveSupport::JSON::Encoding'], method: :escape_html_entities_in_json=).each do |result|
      setting = result[:call].first_arg

      if false? setting
        warn :result => result,
          :warning_type => "Cross-Site Scripting",
          :warning_code => :json_html_escape_module,
          :message => msg("HTML entities in JSON are not escaped by default"),
          :confidence => :medium,
          :file => "config/environments/production.rb",
          :cwe_id => [79]
      end
    end
  end
end
