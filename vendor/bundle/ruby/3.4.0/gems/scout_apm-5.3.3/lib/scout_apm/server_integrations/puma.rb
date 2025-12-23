module ScoutApm
  module ServerIntegrations
    class Puma
      attr_reader :logger

      def initialize(logger)
        @logger = logger
      end

      def name
        :puma
      end

      def forking?
        return false unless defined?(::Puma)
        options = ::Puma.cli_config.instance_variable_get(:@options)
        options[:preload_app]
      rescue
        false
      end

      def present?
        defined?(::Puma) && (File.basename($0) =~ /\Apuma/)
      end

      # Puma::UserFileDefaultOptions exposes `options` based on three underlying
      # hashes: user_options, file_options, and default_options. While getting an `options`
      # key consults all three underlying hashes, setting an `options` key only sets the
      # user_options hash:
      #
      #    def [](key)
      #      fetch(key)
      #    end
      #
      #    def []=(key, value)
      #      user_options[key] = value
      #    end
      #
      #    def fetch(key, default_value = nil)
      #      return user_options[key]    if user_options.key?(key)
      #      return file_options[key]    if file_options.key?(key)
      #      return default_options[key] if default_options.key?(key)
      #
      #      default_value
      #    end
      #
      # Because of this, we can't read options[:before_worker_boot], modify, and then re-set
      # options[:before_worker_boot], since doing so could cause duplication if `before_worker_boot`
      # exists on the other two underlying hashes (file_options, default_options).
      #
      # To get around this, we explicitly read from `user_options` only, and still set using `options[]=`,
      # which Puma allows for setting `user_options`.
      #
      def install
        old = ::Puma.cli_config.options.user_options[:before_worker_boot] || []
        new = Array(old) + [Proc.new do
          logger.info "Installing Puma worker loop."
          ScoutApm::Agent.instance.start_background_worker
        end]

        ::Puma.cli_config.options[:before_worker_boot] = new
      rescue
        logger.warn "Unable to install Puma worker loop: #{$!.message}"
      end

      def found?
        true
      end
    end
  end
end
