module DatabaseCleaner
  class Safeguard
    class Error < Exception
      class RemoteDatabaseUrl < Error
        def initialize
          super("ENV['DATABASE_URL'] is set to a remote URL. Please refer to https://github.com/DatabaseCleaner/database_cleaner#safeguards")
        end
      end

      class ProductionEnv < Error
        def initialize(env)
          super("ENV['#{env}'] is set to production. Please refer to https://github.com/DatabaseCleaner/database_cleaner#safeguards")
        end
      end

      class UrlNotAllowed < Error
        def initialize
          super("ENV['DATABASE_URL'] is set to a URL that is not on the allowlist. Please refer to https://github.com/DatabaseCleaner/database_cleaner#safeguards")
        end
      end
    end

    class AllowedUrl
      def run
        return if skip?
        raise Error::UrlNotAllowed if database_url_not_allowed?
      end

      private

        def database_url_not_allowed?
          !DatabaseCleaner.url_allowlist.any? {|allowed| allowed === ENV['DATABASE_URL'] }
        end

        def skip?
          !DatabaseCleaner.url_allowlist
        end
    end


    class RemoteDatabaseUrl
      LOCAL = %w(localhost 127.0.0.1)

      def run
        raise Error::RemoteDatabaseUrl if !skip? && given?
      end

      private

        def given?
          remote?(ENV['DATABASE_URL'])
        end

        def remote?(url)
          return false unless url

          parsed = URI.parse(url)
          return false if parsed.scheme == 'sqlite3:'

          host = parsed.host
          return false unless host
          return false if LOCAL.include?(host)
          return false if host.end_with? '.local'
          true
        end

        def skip?
          ENV['DATABASE_CLEANER_ALLOW_REMOTE_DATABASE_URL'] ||
            DatabaseCleaner.allow_remote_database_url ||
            DatabaseCleaner.url_allowlist
        end
    end

    class Production
      KEYS = %w(ENV APP_ENV RACK_ENV RAILS_ENV)

      def run
        raise Error::ProductionEnv.new(key) if !skip? && given?
      end

      private

        def given?
          !!key
        end

        def key
          @key ||= KEYS.detect { |key| ENV[key] == 'production' }
        end

        def skip?
          ENV['DATABASE_CLEANER_ALLOW_PRODUCTION'] ||
            DatabaseCleaner.allow_production
        end
    end

    CHECKS = [
      RemoteDatabaseUrl,
      Production,
      AllowedUrl
    ]

    def run
      CHECKS.each { |const| const.new.run }
    end
  end
end
