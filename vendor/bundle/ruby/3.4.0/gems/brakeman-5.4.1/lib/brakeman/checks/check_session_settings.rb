require 'brakeman/checks/base_check'

#Checks for session key length and http_only settings
class Brakeman::CheckSessionSettings < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for session key length and http_only settings"

  def initialize *args
    super

    unless tracker.options[:rails3]
      @session_settings = Sexp.new(:colon2, Sexp.new(:const, :ActionController), :Base)
    else
      @session_settings = nil
    end
  end

  def run_check
    settings = tracker.config.session_settings 

    check_for_issues settings, @app_tree.file_path("config/environment.rb")

    session_store = @app_tree.file_path("config/initializers/session_store.rb")
    secret_token = @app_tree.file_path("config/initializers/secret_token.rb")

    [session_store, secret_token].each do |file|
      if tracker.initializers[file] and not ignored? file.basename
        process tracker.initializers[file]
      end
    end

    if tracker.options[:rails4]
      check_secrets_yaml
    end
  end

  #Looks for ActionController::Base.session = { ... }
  #in Rails 2.x apps
  #
  #and App::Application.config.secret_token =
  #in Rails 3.x apps
  #
  #and App::Application.config.secret_key_base =
  #in Rails 4.x apps
  def process_attrasgn exp
    if not tracker.options[:rails3] and exp.target == @session_settings and exp.method == :session=
      check_for_issues exp.first_arg, @app_tree.file_path("config/initializers/session_store.rb")
    end

    if tracker.options[:rails3] and settings_target?(exp.target) and
      (exp.method == :secret_token= or exp.method == :secret_key_base=) and string? exp.first_arg

      warn_about_secret_token exp.line, @app_tree.file_path("config/initializers/secret_token.rb")
    end

    exp
  end

  #Looks for Rails3::Application.config.session_store :cookie_store, { ... }
  #in Rails 3.x apps
  def process_call exp
    if tracker.options[:rails3] and settings_target?(exp.target) and exp.method == :session_store
      check_for_rails3_issues exp.second_arg, @app_tree.file_path("config/initializers/session_store.rb")
    end

    exp
  end

  private

  def settings_target? exp
    call? exp and
    exp.method == :config and
    node_type? exp.target, :colon2 and
    exp.target.rhs == :Application
  end

  def check_for_issues settings, file
    if settings and hash? settings
      if value = (hash_access(settings, :session_http_only) ||
                  hash_access(settings, :http_only) ||
                  hash_access(settings, :httponly))

        if false? value
          warn_about_http_only value.line, file
        end
      end

      if value = hash_access(settings, :secret)
        if string? value
          warn_about_secret_token value.line, file
        end
      end
    end
  end

  def check_for_rails3_issues settings, file
    if settings and hash? settings
      if value = hash_access(settings, :httponly)
        if false? value
          warn_about_http_only value.line, file
        end
      end

      if value = hash_access(settings, :secure)
        if false? value
          warn_about_secure_only value.line, file
        end
      end
    end
  end

  def check_secrets_yaml
    secrets_file = @app_tree.file_path("config/secrets.yml")

    if secrets_file.exists? and not ignored? "secrets.yml" and not ignored? "config/*.yml"
      yaml = secrets_file.read
      require 'date' # https://github.com/dtao/safe_yaml/issues/80
      require 'safe_yaml/load'
      begin
        secrets = SafeYAML.load yaml
      rescue Psych::SyntaxError, RuntimeError => e
        Brakeman.notify "[Notice] #{self.class}: Unable to parse `#{secrets_file}`"
        Brakeman.debug "Failed to parse #{secrets_file}: #{e.inspect}"
        return
      end

      if secrets && secrets["production"] and secret = secrets["production"]["secret_key_base"]
        unless secret.include? "<%="
          line = yaml.lines.find_index { |l| l.include? secret } + 1

          warn_about_secret_token line, @app_tree.file_path(secrets_file)
        end
      end
    end
  end

  def warn_about_http_only line, file
    warn :warning_type => "Session Setting",
      :warning_code => :http_cookies,
      :message => "Session cookies should be set to HTTP only",
      :confidence => :high,
      :line => line,
      :file => file,
      :cwe_id => [1004]

  end

  def warn_about_secret_token line, file
    warn :warning_type => "Session Setting",
      :warning_code => :session_secret,
      :message => "Session secret should not be included in version control",
      :confidence => :high,
      :line => line,
      :file => file,
      :cwe_id => [798]
  end

  def warn_about_secure_only line, file
    warn :warning_type => "Session Setting",
      :warning_code => :secure_cookies,
      :message => "Session cookie should be set to secure only",
      :confidence => :high,
      :line => line,
      :file => file,
      :cwe_id => [614]
  end

  def ignored? file
    [".", "config", "config/initializers"].each do |dir|
      ignore_file = @app_tree.file_path("#{dir}/.gitignore")
      if @app_tree.exists? ignore_file
        input = ignore_file.read 

        return true if input.include? file
      end
    end

    false
  end
end
