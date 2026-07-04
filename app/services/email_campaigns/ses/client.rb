require 'net/http'

module EmailCampaigns
  module Ses
    # Shared SES error. Callers (provisioner, jobs, controller) rescue EmailCampaigns::Ses::Error.
    class Error < StandardError; end

    # Low-level, gem-free SESv2 HTTPS client. Signs requests with Aws::Sigv4::Signer
    # (service: ses) and dispatches via Net::HTTP. No aws-sdk-ses dependency.
    class Client
      API_VERSION_PATH = '/v2/email'.freeze

      def create_email_identity(domain)
        post("#{API_VERSION_PATH}/identities", { EmailIdentity: domain }, idempotent: true)
      end

      def get_email_identity(identity)
        get("#{API_VERSION_PATH}/identities/#{ERB::Util.url_encode(identity)}")
      end

      def create_configuration_set(name)
        post("#{API_VERSION_PATH}/configuration-sets", { ConfigurationSetName: name }, idempotent: true)
      end

      def put_configuration_set_event_destination(configuration_set:, destination_name:, sns_topic_arn:, event_types:)
        path = "#{API_VERSION_PATH}/configuration-sets/#{ERB::Util.url_encode(configuration_set)}/event-destinations"
        body = {
          EventDestinationName: destination_name,
          EventDestination: {
            Enabled: true,
            MatchingEventTypes: event_types,
            SnsDestination: { TopicArn: sns_topic_arn }
          }
        }
        post(path, body, idempotent: true)
      end

      def send_email(from:, to:, subject:, html_body:, text_body: nil,
                     configuration_set: nil, reply_to: nil, headers: nil)
        body = {
          FromEmailAddress: from,
          Destination: { ToAddresses: [to] },
          ReplyToAddresses: [reply_to].compact.presence,
          ConfigurationSetName: configuration_set,
          Content: { Simple: {
            Subject: { Data: subject },
            Body: email_body(html_body, text_body),
            Headers: ses_headers(headers)
          }.compact }
        }.compact
        post("#{API_VERSION_PATH}/outbound-emails", body)
      end

      private

      def email_body(html_body, text_body)
        { Html: { Data: html_body }, Text: text_body.present? ? { Data: text_body } : nil }.compact
      end

      def ses_headers(headers)
        return nil if headers.blank?

        headers.map { |name, value| { Name: name, Value: value } }
      end

      def host
        @host ||= "email.#{EmailCampaigns::Config.region}.amazonaws.com"
      end

      def signer
        @signer ||= Aws::Sigv4::Signer.new(
          service: 'ses', region: EmailCampaigns::Config.region, **signer_credentials
        )
      end

      # Static keys when explicitly configured; otherwise the default provider chain
      # resolves the EC2 instance-role creds (temporary, auto-rotating, with session token)
      # via IMDS — so SES works without any static secret in the environment.
      def signer_credentials
        static = EmailCampaigns::Config.static_credentials
        return { credentials: static } if static

        { credentials_provider: Aws::CredentialProviderChain.new.resolve }
      end

      def get(path)
        dispatch('GET', path, '')
      end

      def post(path, payload, idempotent: false)
        dispatch('POST', path, payload.to_json)
      rescue Error => e
        raise unless idempotent && already_exists?(e)

        {}
      end

      def dispatch(method, path, body)
        url = "https://#{host}#{path}"
        headers = { 'host' => host, 'content-type' => 'application/json' }
        signature = signer.sign_request(http_method: method, url: url, headers: headers, body: body)
        headers.merge!(signature.headers)
        execute(method, url, headers, body)
      end

      def execute(method, url, headers, body)
        uri = URI.parse(url)
        request = build_request(method, uri, headers, body)
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(request) }
        handle(response)
      rescue Error
        raise
      rescue StandardError => e
        raise Error, e.message
      end

      def build_request(method, uri, headers, body)
        klass = method == 'GET' ? Net::HTTP::Get : Net::HTTP::Post
        request = klass.new(uri)
        headers.each { |key, value| request[key] = value }
        request.body = body unless method == 'GET'
        request
      end

      def handle(response)
        parsed = parse(response.body)
        return parsed if response.code.to_i.between?(200, 299)

        raise Error, "#{response.code} #{parsed['message'] || parsed['Message'] || response.body}"
      end

      def parse(body)
        return {} if body.blank?

        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      def already_exists?(error)
        # SES is inconsistent: configuration sets return "already exists." (409) but
        # email identities return "... already exist." (400, no trailing "s"). Match
        # both spellings so idempotent create paths recover instead of failing.
        error.message.include?('409') || error.message.match?(/already.?exist/i)
      end
    end
  end
end
