require 'brakeman/checks/base_check'

class Brakeman::CheckSecrets < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Checks for secrets stored in source code"

  def run_check
    check_constants
  end

  def check_constants
    @warned = Set.new

    @tracker.constants.each do |constant|
      name = constant.name_array.last
      value = constant.value

      if string? value and not value.value.empty? and looks_like_secret? name
        match = [name, value, value.line]

        unless @warned.include? match
          @warned << match

          warn :warning_code => :secret_in_source,
            :warning_type => "Authentication",
            :message => msg("Hardcoded value for ", msg_code(name), " in source code"),
            :confidence => :medium,
            :file => constant.file,
            :line => constant.line,
            :cwe_id => [798]
        end
      end
    end
  end

  def looks_like_secret? name
    # REST_AUTH_SITE_KEY is the pepper in Devise
    name.match(/password|secret|(rest_auth_site|api)_key$/i)
  end
end
