# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS

  class Subscription

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

    # A map of the subscription's attributes. Attributes in this map
    # include the following:
    #
    # * `ConfirmationWasAuthenticated` – `true` if the subscription
    #   confirmation request was authenticated.
    #
    # * `DeliveryPolicy` – The JSON serialization of the subscription's
    #   delivery policy.
    #
    # * `EffectiveDeliveryPolicy` – The JSON serialization of the effective
    #   delivery policy that takes into account the topic delivery policy
    #   and account system defaults.
    #
    # * `FilterPolicy` – The filter policy JSON that is assigned to the
    #   subscription. For more information, see [Amazon SNS Message
    #   Filtering][1] in the *Amazon SNS Developer Guide*.
    #
    # * `FilterPolicyScope` – This attribute lets you choose the filtering
    #   scope by using one of the following string value types:
    #
    #   * `MessageAttributes` (default) – The filter is applied on the
    #     message attributes.
    #
    #   * `MessageBody` – The filter is applied on the message body.
    #
    # * `Owner` – The Amazon Web Services account ID of the subscription's
    #   owner.
    #
    # * `PendingConfirmation` – `true` if the subscription hasn't been
    #   confirmed. To confirm a pending subscription, call the
    #   `ConfirmSubscription` action with a confirmation token.
    #
    # * `RawMessageDelivery` – `true` if raw message delivery is enabled for
    #   the subscription. Raw messages are free of JSON formatting and can
    #   be sent to HTTP/S and Amazon SQS endpoints.
    #
    # * `RedrivePolicy` – When specified, sends undeliverable messages to
    #   the specified Amazon SQS dead-letter queue. Messages that can't be
    #   delivered due to client errors (for example, when the subscribed
    #   endpoint is unreachable) or server errors (for example, when the
    #   service that powers the subscribed endpoint becomes unavailable) are
    #   held in the dead-letter queue for further analysis or reprocessing.
    #
    # * `SubscriptionArn` – The subscription's ARN.
    #
    # * `TopicArn` – The topic ARN that the subscription is associated with.
    #
    # The following attribute applies only to Amazon Kinesis Data Firehose
    # delivery stream subscriptions:
    #
    # * `SubscriptionRoleArn` – The ARN of the IAM role that has the
    #   following:
    #
    #   * Permission to write to the Kinesis Data Firehose delivery stream
    #
    #   * Amazon SNS listed as a trusted entity
    #
    #   Specifying a valid ARN for this attribute is required for Kinesis
    #   Data Firehose delivery stream subscriptions. For more information,
    #   see [Fanout to Kinesis Data Firehose delivery streams][2] in the
    #   *Amazon SNS Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html
    # [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-firehose-as-subscriber.html
    # @return [Hash<String,String>]
    def attributes
      data[:attributes]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # Loads, or reloads {#data} for the current {Subscription}.
    # Returns `self` making it possible to chain methods.
    #
    #     subscription.reload.data
    #
    # @return [self]
    def load
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.get_subscription_attributes(subscription_arn: @arn)
      end
      @data = resp.data
      self
    end
    alias :reload :load

    # @return [Types::GetSubscriptionAttributesResponse]
    #   Returns the data for this {Subscription}. Calls
    #   {Client#get_subscription_attributes} if {#data_loaded?} is `false`.
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
    #   subscription.delete()
    # @param [Hash] options ({})
    # @return [EmptyStructure]
    def delete(options = {})
      options = options.merge(subscription_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.unsubscribe(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   subscription.set_attributes({
    #     attribute_name: "attributeName", # required
    #     attribute_value: "attributeValue",
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :attribute_name
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that this action uses:
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `FilterPolicy` – The simple JSON object that lets your subscriber
    #     receive only a subset of messages, rather than receiving every
    #     message published to the topic.
    #
    #   * `FilterPolicyScope` – This attribute lets you choose the filtering
    #     scope by using one of the following string value types:
    #
    #     * `MessageAttributes` (default) – The filter is applied on the
    #       message attributes.
    #
    #     * `MessageBody` – The filter is applied on the message body.
    #
    #   * `RawMessageDelivery` – When set to `true`, enables raw message
    #     delivery to Amazon SQS or HTTP/S endpoints. This eliminates the need
    #     for the endpoints to process JSON formatting, which is otherwise
    #     created for Amazon SNS metadata.
    #
    #   * `RedrivePolicy` – When specified, sends undeliverable messages to
    #     the specified Amazon SQS dead-letter queue. Messages that can't be
    #     delivered due to client errors (for example, when the subscribed
    #     endpoint is unreachable) or server errors (for example, when the
    #     service that powers the subscribed endpoint becomes unavailable) are
    #     held in the dead-letter queue for further analysis or reprocessing.
    #
    #   The following attribute applies only to Amazon Kinesis Data Firehose
    #   delivery stream subscriptions:
    #
    #   * `SubscriptionRoleArn` – The ARN of the IAM role that has the
    #     following:
    #
    #     * Permission to write to the Kinesis Data Firehose delivery stream
    #
    #     * Amazon SNS listed as a trusted entity
    #
    #     Specifying a valid ARN for this attribute is required for Kinesis
    #     Data Firehose delivery stream subscriptions. For more information,
    #     see [Fanout to Kinesis Data Firehose delivery streams][1] in the
    #     *Amazon SNS Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-firehose-as-subscriber.html
    # @option options [String] :attribute_value
    #   The new value for the attribute in JSON format.
    # @return [EmptyStructure]
    def set_attributes(options = {})
      options = options.merge(subscription_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.set_subscription_attributes(options)
      end
      resp.data
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
