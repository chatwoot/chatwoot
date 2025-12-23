class Brakeman::CheckForceSSL < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Check that force_ssl setting is enabled in production"

  def run_check
    return if tracker.config.rails.empty? or tracker.config.rails_version.nil?
    return if tracker.config.rails_version < "3.1.0"

    force_ssl = tracker.config.rails[:force_ssl]

    if false? force_ssl or force_ssl.nil?
      line = if sexp? force_ssl
               force_ssl.line
             else
               1
             end

      warn :warning_type => "Missing Encryption",
        :warning_code => :force_ssl_disabled,
        :message => msg("The application does not force use of HTTPS: ", msg_code("config.force_ssl"), " is not enabled"),
        :confidence => :high,
        :file => "config/environments/production.rb",
        :line => line,
        :cwe_id => [311]
    end
  end
end
