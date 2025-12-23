# frozen_string_literal: true

module OAuth
  module TTY
    class Command
      def initialize(stdout, stdin, stderr, arguments)
        @stdout = stdout
        @stdin = stdin
        @stderr = stderr

        @options = {}
        option_parser.parse!(arguments)
      end

      def run
        missing = required_options - options.keys
        if missing.empty?
          _run
        else
          show_missing(missing)
          puts option_parser.help
        end
      end

      def required_options
        []
      end

      protected

      attr_reader :options

      def show_missing(array)
        array = array.map { |s| "--#{s}" }.join(" ")
        OAuth::TTY::CLI.puts_red "Options missing to OAuth CLI: #{array}"
      end

      def xmpp?
        options[:xmpp]
      end

      def verbose?
        options[:verbose]
      end

      def puts(string = nil)
        @stdout.puts(string)
      end

      def alert(string = nil)
        @stderr.puts(string)
      end

      def parameters
        @parameters ||= begin
          escaped_pairs = options[:params].collect do |pair|
            if /:/.match?(pair)
              Hash[*pair.split(":", 2)].collect do |k, v|
                [CGI.escape(k.strip), CGI.escape(v.strip)].join("=")
              end
            else
              pair
            end
          end

          querystring = escaped_pairs * "&"
          cli_params = CGI.parse(querystring)

          {
            "oauth_consumer_key" => options[:oauth_consumer_key],
            "oauth_nonce" => options[:oauth_nonce],
            "oauth_timestamp" => options[:oauth_timestamp],
            "oauth_token" => options[:oauth_token],
            "oauth_signature_method" => options[:oauth_signature_method],
            "oauth_version" => options[:oauth_version]
          }.reject { |_k, v| v.nil? || v == "" }.merge(cli_params)
        end
      end

      def option_parser
        @option_parser ||= OptionParser.new do |opts|
          opts.banner = "Usage: oauth <command> [ARGS]"

          _option_parser_defaults
          _option_parser_common(opts)
          _option_parser_sign_and_query(opts)
          _option_parser_authorization(opts)
        end
      end

      def _option_parser_defaults
        options[:oauth_nonce] = OAuth::Helper.generate_key
        options[:oauth_signature_method] = "HMAC-SHA1"
        options[:oauth_timestamp] = OAuth::Helper.generate_timestamp
        options[:oauth_version] = "1.0"
        options[:method] = :post
        options[:params] = []
        options[:scheme] = :header
        options[:version] = "1.0"
      end

      def _option_parser_common(opts)
        ## Common Options

        opts.on("-B", "--body", "Use the request body for OAuth parameters.") do
          options[:scheme] = :body
        end

        opts.on("--consumer-key KEY", "Specifies the consumer key to use.") do |v|
          options[:oauth_consumer_key] = v
        end

        opts.on("--consumer-secret SECRET", "Specifies the consumer secret to use.") do |v|
          options[:oauth_consumer_secret] = v
        end

        opts.on("-H", "--header", "Use the 'Authorization' header for OAuth parameters (default).") do
          options[:scheme] = :header
        end

        opts.on("-Q", "--query-string", "Use the query string for OAuth parameters.") do
          options[:scheme] = :query_string
        end

        opts.on("-O", "--options FILE", "Read options from a file") do |v|
          arguments = open(v).readlines.map { |l| l.chomp.split }.flatten
          options2 = parse_options(arguments)
          options.merge!(options2)
        end
      end

      def _option_parser_sign_and_query(opts)
        opts.separator("\n  options for signing and querying")

        opts.on("--method METHOD", "Specifies the method (e.g. GET) to use when signing.") do |v|
          options[:method] = v
        end

        opts.on("--nonce NONCE", "Specifies the nonce to use.") do |v|
          options[:oauth_nonce] = v
        end

        opts.on("--parameters PARAMS", "Specifies the parameters to use when signing.") do |v|
          options[:params] << v
        end

        opts.on("--signature-method METHOD", "Specifies the signature method to use; defaults to HMAC-SHA1.") do |v|
          options[:oauth_signature_method] = v
        end

        opts.on("--token TOKEN", "Specifies the token to use.") do |v|
          options[:oauth_token] = v
        end

        opts.on("--secret SECRET", "Specifies the token secret to use.") do |v|
          options[:oauth_token_secret] = v
        end

        opts.on("--timestamp TIMESTAMP", "Specifies the timestamp to use.") do |v|
          options[:oauth_timestamp] = v
        end

        opts.on("--realm REALM", "Specifies the realm to use.") do |v|
          options[:realm] = v
        end

        opts.on("--uri URI", "Specifies the URI to use when signing.") do |v|
          options[:uri] = v
        end

        opts.on("--version [VERSION]", "Specifies the OAuth version to use.") do |v|
          options[:oauth_version] = v
        end

        opts.on("--no-version", "Omit oauth_version.") do
          options[:oauth_version] = nil
        end

        opts.on("--xmpp", "Generate XMPP stanzas.") do
          options[:xmpp] = true
          options[:method] ||= "iq"
        end

        opts.on("-v", "--verbose", "Be verbose.") do
          options[:verbose] = true
        end
      end

      def _option_parser_authorization(opts)
        opts.separator("\n  options for authorization")

        opts.on("--access-token-url URL", "Specifies the access token URL.") do |v|
          options[:access_token_url] = v
        end

        opts.on("--authorize-url URL", "Specifies the authorization URL.") do |v|
          options[:authorize_url] = v
        end

        opts.on("--callback-url URL", "Specifies a callback URL.") do |v|
          options[:oauth_callback] = v
        end

        opts.on("--request-token-url URL", "Specifies the request token URL.") do |v|
          options[:request_token_url] = v
        end

        opts.on("--scope SCOPE", "Specifies the scope (Google-specific).") do |v|
          options[:scope] = v
        end
      end
    end
  end
end
