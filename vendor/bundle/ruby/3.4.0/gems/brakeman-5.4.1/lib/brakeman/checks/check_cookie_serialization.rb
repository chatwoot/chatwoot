require 'brakeman/checks/base_check'

class Brakeman::CheckCookieSerialization < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for use of Marshal for cookie serialization"

  def run_check
    tracker.find_call(target: :'Rails.application.config.action_dispatch', method: :cookies_serializer=).each do |result|
      setting = result[:call].first_arg

      if symbol? setting and [:marshal, :hybrid].include? setting.value
        warn :result => result,
          :warning_type => "Remote Code Execution",
          :warning_code => :unsafe_cookie_serialization,
          :message => msg("Use of unsafe cookie serialization strategy ", msg_code(setting.value.inspect), " might lead to remote code execution"),
          :confidence => :medium,
          :link_path => "unsafe_deserialization",
          :cwe_id => [565, 502]
      end
    end
  end
end
