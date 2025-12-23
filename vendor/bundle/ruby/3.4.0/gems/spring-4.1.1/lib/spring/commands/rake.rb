module Spring
  module Commands
    class Rake
      class << self
        attr_accessor :environment_matchers
      end

      self.environment_matchers = {
        :default     => "test",
        /^test($|:)/ => "test"
      }

      def env(args)
        # This is an adaption of the matching that Rake itself does.
        # See: https://github.com/jimweirich/rake/blob/3754a7639b3f42c2347857a0878beb3523542aee/lib/rake/application.rb#L691-L692
        if env = args.grep(/^(RAILS|RACK)_ENV=(.*)$/m).last
          return env.split("=").last
        end

        self.class.environment_matchers.each do |matcher, environment|
          return environment if matcher === (args.first || :default)
        end

        nil
      end
    end

    Spring.register_command "rake", Rake.new
  end
end
