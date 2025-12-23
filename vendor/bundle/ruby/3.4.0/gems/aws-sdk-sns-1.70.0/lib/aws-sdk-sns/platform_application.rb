# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS

  class PlatformApplication

    extend Aws::Deprecations

    # @overload def initialize(arn, options = {})
    #   @param [String] arn
    #   @option options [Client] :client
    # @overload def initialize(options = {})
    #   @option options [required, String] :arn
    #   @option options [Client] :client
    def initialize(*args)
      options = Hash === args.last ? args.pop.dup : {}
      @arn = extract_arn(args, options)
      @data = options.delete(:data)
      @client = options.delete(:client) || Client.new(options)
      @waiter_block_warned = false
    end

    # @!group Read-Only Attributes

    # @return [String]
    def arn
      @arn
    end

    # Attributes include the following:
    #
    # * `AppleCertificateExpiryDate` – The expiry date of the SSL
    #   certificate used to configure certificate-based authentication.
    #
    # * `ApplePlatformTeamID` – The Apple developer account ID used to
    #   configure token-based authentication.
    #
    # * `ApplePlatformBundleID` – The app identifier used to configure
    #   token-based authentication.
    #
    # * `EventEndpointCreated` – Topic ARN to which EndpointCreated event
    #   notifications should be sent.
    #
    # * `EventEndpointDeleted` – Topic ARN to which EndpointDeleted event
    #   notifications should be sent.
    #
    # * `EventEndpointUpdated` – Topic ARN to which EndpointUpdate event
    #   notifications should be sent.
    #
    # * `EventDeliveryFailure` – Topic ARN to which DeliveryFailure event
    #   notifications should be sent upon Direct Publish delivery failure
    #   (permanent) to one of the application's endpoints.
    # @return [Hash<String,String>]
    def attributes
      data[:attributes]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # Loads, or reloads {#data} for the current {PlatformApplication}.
    # Returns `self` making it possible to chain methods.
    #
    #     platform_application.reload.data
    #
    # @return [self]
    def load
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.get_platform_application_attributes(platform_application_arn: @arn)
      end
      @data = resp.data
      self
    end
    alias :reload :load

    # @return [Types::GetPlatformApplicationAttributesResponse]
    #   Returns the data for this {PlatformApplication}. Calls
    #   {Client#get_platform_application_attributes} if {#data_loaded?} is `false`.
    def data
      load unless @data
      @data
    end

    # @return [Boolean]
    #   Returns `true` if this resource is loaded.  Accessing attributes or
    #   {#data} on an unloaded resource will trigger a call to {#load}.
    def data_loaded?
      !!@data
    end

    # @!group Actions

    # @example Request syntax with placeholder values
    #
    #   platformendpoint = platform_application.create_platform_endpoint({
    #     token: "String", # required
    #     custom_user_data: "String",
    #     attributes: {
    #       "String" => "String",
    #     },
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :token
    #   Unique identifier created by the notification service for an app on a
    #   device. The specific name for Token will vary, depending on which
    #   notification service is being used. For example, when using APNS as
    #   the notification service, you need the device token. Alternatively,
    #   when using GCM (Firebase Cloud Messaging) or ADM, the device token
    #   equivalent is called the registration ID.
    # @option options [String] :custom_user_data
    #   Arbitrary user data to associate with the endpoint. Amazon SNS does
    #   not use this data. The data must be in UTF-8 format and less than 2KB.
    # @option options [Hash<String,String>] :attributes
    #   For a list of attributes, see [SetEndpointAttributes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetEndpointAttributes.html
    # @return [PlatformEndpoint]
    def create_platform_endpoint(options = {})
      options = options.merge(platform_application_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.create_platform_endpoint(options)
      end
      PlatformEndpoint.new(
        arn: resp.data.endpoint_arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   platform_application.delete()
    # @param [Hash] options ({})
    # @return [EmptyStructure]
    def delete(options = {})
      options = options.merge(platform_application_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.delete_platform_application(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   platform_application.set_attributes({
    #     attributes: { # required
    #       "String" => "String",
    #     },
    #   })
    # @param [Hash] options ({})
    # @option options [required, Hash<String,String>] :attributes
    #   A map of the platform application attributes. Attributes in this map
    #   include the following:
    #
    #   * `PlatformCredential` – The credential received from the notification
    #     service.
    #
    #     * For ADM, `PlatformCredential`is client secret.
    #
    #     * For Apple Services using certificate credentials,
    #       `PlatformCredential` is private key.
    #
    #     * For Apple Services using token credentials, `PlatformCredential`
    #       is signing key.
    #
    #     * For GCM (Firebase Cloud Messaging), `PlatformCredential` is API
    #       key.
    #   ^
    #
    #   * `PlatformPrincipal` – The principal received from the notification
    #     service.
    #
    #     * For ADM, `PlatformPrincipal`is client id.
    #
    #     * For Apple Services using certificate credentials,
    #       `PlatformPrincipal` is SSL certificate.
    #
    #     * For Apple Services using token credentials, `PlatformPrincipal` is
    #       signing key ID.
    #
    #     * For GCM (Firebase Cloud Messaging), there is no
    #       `PlatformPrincipal`.
    #   ^
    #
    #   * `EventEndpointCreated` – Topic ARN to which `EndpointCreated` event
    #     notifications are sent.
    #
    #   * `EventEndpointDeleted` – Topic ARN to which `EndpointDeleted` event
    #     notifications are sent.
    #
    #   * `EventEndpointUpdated` – Topic ARN to which `EndpointUpdate` event
    #     notifications are sent.
    #
    #   * `EventDeliveryFailure` – Topic ARN to which `DeliveryFailure` event
    #     notifications are sent upon Direct Publish delivery failure
    #     (permanent) to one of the application's endpoints.
    #
    #   * `SuccessFeedbackRoleArn` – IAM role ARN used to give Amazon SNS
    #     write access to use CloudWatch Logs on your behalf.
    #
    #   * `FailureFeedbackRoleArn` – IAM role ARN used to give Amazon SNS
    #     write access to use CloudWatch Logs on your behalf.
    #
    #   * `SuccessFeedbackSampleRate` – Sample rate percentage (0-100) of
    #     successfully delivered messages.
    #
    #   The following attributes only apply to `APNs` token-based
    #   authentication:
    #
    #   * `ApplePlatformTeamID` – The identifier that's assigned to your
    #     Apple developer account team.
    #
    #   * `ApplePlatformBundleID` – The bundle identifier that's assigned to
    #     your iOS app.
    # @return [EmptyStructure]
    def set_attributes(options = {})
      options = options.merge(platform_application_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.set_platform_application_attributes(options)
      end
      resp.data
    end

    # @!group Associations

    # @example Request syntax with placeholder values
    #
    #   platform_application.endpoints()
    # @param [Hash] options ({})
    # @return [PlatformEndpoint::Collection]
    def endpoints(options = {})
      batches = Enumerator.new do |y|
        options = options.merge(platform_application_arn: @arn)
        resp = Aws::Plugins::UserAgent.feature('resource') do
          @client.list_endpoints_by_platform_application(options)
        end
        resp.each_page do |page|
          batch = []
          page.data.endpoints.each do |e|
            batch << PlatformEndpoint.new(
              arn: e.endpoint_arn,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      PlatformEndpoint::Collection.new(batches)
    end

    # @deprecated
    # @api private
    def identifiers
      { arn: @arn }
    end
    deprecated(:identifiers)

    private

    def extract_arn(args, options)
      value = args[0] || options.delete(:arn)
      case value
      when String then value
      when nil then raise ArgumentError, "missing required option :arn"
      else
        msg = "expected :arn to be a String, got #{value.class}"
        raise ArgumentError, msg
      end
    end

    class Collection < Aws::Resources::Collection; end
  end
end
