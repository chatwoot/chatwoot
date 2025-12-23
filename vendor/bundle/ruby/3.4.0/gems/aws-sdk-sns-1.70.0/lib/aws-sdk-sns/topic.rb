# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS

  class Topic

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

    # A map of the topic's attributes. Attributes in this map include the
    # following:
    #
    # * `DeliveryPolicy` – The JSON serialization of the topic's delivery
    #   policy.
    #
    # * `DisplayName` – The human-readable name used in the `From` field for
    #   notifications to `email` and `email-json` endpoints.
    #
    # * `EffectiveDeliveryPolicy` – The JSON serialization of the effective
    #   delivery policy, taking system defaults into account.
    #
    # * `Owner` – The Amazon Web Services account ID of the topic's owner.
    #
    # * `Policy` – The JSON serialization of the topic's access control
    #   policy.
    #
    # * `SignatureVersion` – The signature version corresponds to the
    #   hashing algorithm used while creating the signature of the
    #   notifications, subscription confirmations, or unsubscribe
    #   confirmation messages sent by Amazon SNS.
    #
    #   * By default, `SignatureVersion` is set to **1**. The signature is a
    #     Base64-encoded **SHA1withRSA** signature.
    #
    #   * When you set `SignatureVersion` to **2**. Amazon SNS uses a
    #     Base64-encoded **SHA256withRSA** signature.
    #
    #     <note markdown="1"> If the API response does not include the `SignatureVersion`
    #     attribute, it means that the `SignatureVersion` for the topic has
    #     value **1**.
    #
    #      </note>
    #
    # * `SubscriptionsConfirmed` – The number of confirmed subscriptions for
    #   the topic.
    #
    # * `SubscriptionsDeleted` – The number of deleted subscriptions for the
    #   topic.
    #
    # * `SubscriptionsPending` – The number of subscriptions pending
    #   confirmation for the topic.
    #
    # * `TopicArn` – The topic's ARN.
    #
    # * `TracingConfig` – Tracing mode of an Amazon SNS topic. By default
    #   `TracingConfig` is set to `PassThrough`, and the topic passes
    #   through the tracing header it receives from an Amazon SNS publisher
    #   to its subscriptions. If set to `Active`, Amazon SNS will vend X-Ray
    #   segment data to topic owner account if the sampled flag in the
    #   tracing header is true. This is only supported on standard topics.
    #
    # The following attribute applies only to [server-side-encryption][1]:
    #
    # * `KmsMasterKeyId` - The ID of an Amazon Web Services managed customer
    #   master key (CMK) for Amazon SNS or a custom CMK. For more
    #   information, see [Key Terms][2]. For more examples, see [KeyId][3]
    #   in the *Key Management Service API Reference*.
    #
    # ^
    #
    # The following attributes apply only to [FIFO topics][4]:
    #
    # * `FifoTopic` – When this is set to `true`, a FIFO topic is created.
    #
    # * `ContentBasedDeduplication` – Enables content-based deduplication
    #   for FIFO topics.
    #
    #   * By default, `ContentBasedDeduplication` is set to `false`. If you
    #     create a FIFO topic and this attribute is `false`, you must
    #     specify a value for the `MessageDeduplicationId` parameter for the
    #     [Publish][5] action.
    #
    #   * When you set `ContentBasedDeduplication` to `true`, Amazon SNS
    #     uses a SHA-256 hash to generate the `MessageDeduplicationId` using
    #     the body of the message (but not the attributes of the message).
    #
    #     (Optional) To override the generated value, you can specify a
    #     value for the `MessageDeduplicationId` parameter for the `Publish`
    #     action.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    # [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    # [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    # [4]: https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html
    # [5]: https://docs.aws.amazon.com/sns/latest/api/API_Publish.html
    # @return [Hash<String,String>]
    def attributes
      data[:attributes]
    end

    # @!endgroup

    # @return [Client]
    def client
      @client
    end

    # Loads, or reloads {#data} for the current {Topic}.
    # Returns `self` making it possible to chain methods.
    #
    #     topic.reload.data
    #
    # @return [self]
    def load
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.get_topic_attributes(topic_arn: @arn)
      end
      @data = resp.data
      self
    end
    alias :reload :load

    # @return [Types::GetTopicAttributesResponse]
    #   Returns the data for this {Topic}. Calls
    #   {Client#get_topic_attributes} if {#data_loaded?} is `false`.
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
    #   topic.add_permission({
    #     label: "label", # required
    #     aws_account_id: ["delegate"], # required
    #     action_name: ["action"], # required
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :label
    #   A unique identifier for the new policy statement.
    # @option options [required, Array<String>] :aws_account_id
    #   The Amazon Web Services account IDs of the users (principals) who will
    #   be given access to the specified actions. The users must have Amazon
    #   Web Services account, but do not need to be signed up for this
    #   service.
    # @option options [required, Array<String>] :action_name
    #   The action you want to allow for the specified principal(s).
    #
    #   Valid values: Any Amazon SNS action name, for example `Publish`.
    # @return [EmptyStructure]
    def add_permission(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.add_permission(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   subscription = topic.confirm_subscription({
    #     token: "token", # required
    #     authenticate_on_unsubscribe: "authenticateOnUnsubscribe",
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :token
    #   Short-lived token sent to an endpoint during the `Subscribe` action.
    # @option options [String] :authenticate_on_unsubscribe
    #   Disallows unauthenticated unsubscribes of the subscription. If the
    #   value of this parameter is `true` and the request has an Amazon Web
    #   Services signature, then only the topic owner and the subscription
    #   owner can unsubscribe the endpoint. The unsubscribe action requires
    #   Amazon Web Services authentication.
    # @return [Subscription]
    def confirm_subscription(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.confirm_subscription(options)
      end
      Subscription.new(
        arn: resp.data.subscription_arn,
        client: @client
      )
    end

    # @example Request syntax with placeholder values
    #
    #   topic.delete()
    # @param [Hash] options ({})
    # @return [EmptyStructure]
    def delete(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.delete_topic(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   topic.publish({
    #     target_arn: "String",
    #     phone_number: "String",
    #     message: "message", # required
    #     subject: "subject",
    #     message_structure: "messageStructure",
    #     message_attributes: {
    #       "String" => {
    #         data_type: "String", # required
    #         string_value: "String",
    #         binary_value: "data",
    #       },
    #     },
    #     message_deduplication_id: "String",
    #     message_group_id: "String",
    #   })
    # @param [Hash] options ({})
    # @option options [String] :target_arn
    #   If you don't specify a value for the `TargetArn` parameter, you must
    #   specify a value for the `PhoneNumber` or `TopicArn` parameters.
    # @option options [String] :phone_number
    #   The phone number to which you want to deliver an SMS message. Use
    #   E.164 format.
    #
    #   If you don't specify a value for the `PhoneNumber` parameter, you
    #   must specify a value for the `TargetArn` or `TopicArn` parameters.
    # @option options [required, String] :message
    #   The message you want to send.
    #
    #   If you are publishing to a topic and you want to send the same message
    #   to all transport protocols, include the text of the message as a
    #   String value. If you want to send different messages for each
    #   transport protocol, set the value of the `MessageStructure` parameter
    #   to `json` and use a JSON object for the `Message` parameter.
    #
    #
    #
    #   Constraints:
    #
    #   * With the exception of SMS, messages must be UTF-8 encoded strings
    #     and at most 256 KB in size (262,144 bytes, not 262,144 characters).
    #
    #   * For SMS, each message can contain up to 140 characters. This
    #     character limit depends on the encoding schema. For example, an SMS
    #     message can contain 160 GSM characters, 140 ASCII characters, or 70
    #     UCS-2 characters.
    #
    #     If you publish a message that exceeds this size limit, Amazon SNS
    #     sends the message as multiple messages, each fitting within the size
    #     limit. Messages aren't truncated mid-word but are cut off at
    #     whole-word boundaries.
    #
    #     The total size limit for a single SMS `Publish` action is 1,600
    #     characters.
    #
    #   JSON-specific constraints:
    #
    #   * Keys in the JSON object that correspond to supported transport
    #     protocols must have simple JSON string values.
    #
    #   * The values will be parsed (unescaped) before they are used in
    #     outgoing messages.
    #
    #   * Outbound notifications are JSON encoded (meaning that the characters
    #     will be reescaped for sending).
    #
    #   * Values have a minimum length of 0 (the empty string, "", is
    #     allowed).
    #
    #   * Values have a maximum length bounded by the overall message size
    #     (so, including multiple protocols may limit message sizes).
    #
    #   * Non-string values will cause the key to be ignored.
    #
    #   * Keys that do not correspond to supported transport protocols are
    #     ignored.
    #
    #   * Duplicate keys are not allowed.
    #
    #   * Failure to parse or validate any key or value in the message will
    #     cause the `Publish` call to return an error (no partial delivery).
    # @option options [String] :subject
    #   Optional parameter to be used as the "Subject" line when the message
    #   is delivered to email endpoints. This field will also be included, if
    #   present, in the standard JSON messages delivered to other endpoints.
    #
    #   Constraints: Subjects must be ASCII text that begins with a letter,
    #   number, or punctuation mark; must not include line breaks or control
    #   characters; and must be less than 100 characters long.
    # @option options [String] :message_structure
    #   Set `MessageStructure` to `json` if you want to send a different
    #   message for each protocol. For example, using one publish action, you
    #   can send a short message to your SMS subscribers and a longer message
    #   to your email subscribers. If you set `MessageStructure` to `json`,
    #   the value of the `Message` parameter must:
    #
    #   * be a syntactically valid JSON object; and
    #
    #   * contain at least a top-level JSON key of "default" with a value
    #     that is a string.
    #
    #   You can define other top-level keys that define the message you want
    #   to send to a specific transport protocol (e.g., "http").
    #
    #   Valid value: `json`
    # @option options [Hash<String,Types::MessageAttributeValue>] :message_attributes
    #   Message attributes for Publish action.
    # @option options [String] :message_deduplication_id
    #   This parameter applies only to FIFO (first-in-first-out) topics. The
    #   `MessageDeduplicationId` can contain up to 128 alphanumeric characters
    #   `(a-z, A-Z, 0-9)` and punctuation ``
    #   (!"#$%&'()*+,-./:;<=>?@[\]^_`\{|\}~) ``.
    #
    #   Every message must have a unique `MessageDeduplicationId`, which is a
    #   token used for deduplication of sent messages. If a message with a
    #   particular `MessageDeduplicationId` is sent successfully, any message
    #   sent with the same `MessageDeduplicationId` during the 5-minute
    #   deduplication interval is treated as a duplicate.
    #
    #   If the topic has `ContentBasedDeduplication` set, the system generates
    #   a `MessageDeduplicationId` based on the contents of the message. Your
    #   `MessageDeduplicationId` overrides the generated one.
    # @option options [String] :message_group_id
    #   This parameter applies only to FIFO (first-in-first-out) topics. The
    #   `MessageGroupId` can contain up to 128 alphanumeric characters `(a-z,
    #   A-Z, 0-9)` and punctuation `` (!"#$%&'()*+,-./:;<=>?@[\]^_`\{|\}~) ``.
    #
    #   The `MessageGroupId` is a tag that specifies that a message belongs to
    #   a specific message group. Messages that belong to the same message
    #   group are processed in a FIFO manner (however, messages in different
    #   message groups might be processed out of order). Every message must
    #   include a `MessageGroupId`.
    # @return [Types::PublishResponse]
    def publish(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.publish(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   topic.remove_permission({
    #     label: "label", # required
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :label
    #   The unique label of the statement you want to remove.
    # @return [EmptyStructure]
    def remove_permission(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.remove_permission(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   topic.set_attributes({
    #     attribute_name: "attributeName", # required
    #     attribute_value: "attributeValue",
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :attribute_name
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that the `SetTopicAttributes` action uses:
    #
    #   * `ApplicationSuccessFeedbackRoleArn` – Indicates failed message
    #     delivery status for an Amazon SNS topic that is subscribed to a
    #     platform application endpoint.
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `DisplayName` – The display name to use for a topic with SMS
    #     subscriptions.
    #
    #   * `Policy` – The policy that defines who can access your topic. By
    #     default, only the topic owner can publish or subscribe to the topic.
    #
    #   * `TracingConfig` – Tracing mode of an Amazon SNS topic. By default
    #     `TracingConfig` is set to `PassThrough`, and the topic passes
    #     through the tracing header it receives from an Amazon SNS publisher
    #     to its subscriptions. If set to `Active`, Amazon SNS will vend X-Ray
    #     segment data to topic owner account if the sampled flag in the
    #     tracing header is true. This is only supported on standard topics.
    #
    #   * HTTP
    #
    #     * `HTTPSuccessFeedbackRoleArn` – Indicates successful message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       HTTP endpoint.
    #
    #     * `HTTPSuccessFeedbackSampleRate` – Indicates percentage of
    #       successful messages to sample for an Amazon SNS topic that is
    #       subscribed to an HTTP endpoint.
    #
    #     * `HTTPFailureFeedbackRoleArn` – Indicates failed message delivery
    #       status for an Amazon SNS topic that is subscribed to an HTTP
    #       endpoint.
    #
    #   * Amazon Kinesis Data Firehose
    #
    #     * `FirehoseSuccessFeedbackRoleArn` – Indicates successful message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Amazon Kinesis Data Firehose endpoint.
    #
    #     * `FirehoseSuccessFeedbackSampleRate` – Indicates percentage of
    #       successful messages to sample for an Amazon SNS topic that is
    #       subscribed to an Amazon Kinesis Data Firehose endpoint.
    #
    #     * `FirehoseFailureFeedbackRoleArn` – Indicates failed message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Amazon Kinesis Data Firehose endpoint.
    #
    #   * Lambda
    #
    #     * `LambdaSuccessFeedbackRoleArn` – Indicates successful message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Lambda endpoint.
    #
    #     * `LambdaSuccessFeedbackSampleRate` – Indicates percentage of
    #       successful messages to sample for an Amazon SNS topic that is
    #       subscribed to an Lambda endpoint.
    #
    #     * `LambdaFailureFeedbackRoleArn` – Indicates failed message delivery
    #       status for an Amazon SNS topic that is subscribed to an Lambda
    #       endpoint.
    #
    #   * Platform application endpoint
    #
    #     * `ApplicationSuccessFeedbackRoleArn` – Indicates successful message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Amazon Web Services application endpoint.
    #
    #     * `ApplicationSuccessFeedbackSampleRate` – Indicates percentage of
    #       successful messages to sample for an Amazon SNS topic that is
    #       subscribed to an Amazon Web Services application endpoint.
    #
    #     * `ApplicationFailureFeedbackRoleArn` – Indicates failed message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Amazon Web Services application endpoint.
    #
    #     <note markdown="1"> In addition to being able to configure topic attributes for message
    #     delivery status of notification messages sent to Amazon SNS
    #     application endpoints, you can also configure application attributes
    #     for the delivery status of push notification messages sent to push
    #     notification services.
    #
    #      For example, For more information, see [Using Amazon SNS Application
    #     Attributes for Message Delivery Status][1].
    #
    #      </note>
    #
    #   * Amazon SQS
    #
    #     * `SQSSuccessFeedbackRoleArn` – Indicates successful message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Amazon SQS endpoint.
    #
    #     * `SQSSuccessFeedbackSampleRate` – Indicates percentage of
    #       successful messages to sample for an Amazon SNS topic that is
    #       subscribed to an Amazon SQS endpoint.
    #
    #     * `SQSFailureFeedbackRoleArn` – Indicates failed message delivery
    #       status for an Amazon SNS topic that is subscribed to an Amazon SQS
    #       endpoint.
    #
    #   <note markdown="1"> The &lt;ENDPOINT&gt;SuccessFeedbackRoleArn and
    #   &lt;ENDPOINT&gt;FailureFeedbackRoleArn attributes are used to give
    #   Amazon SNS write access to use CloudWatch Logs on your behalf. The
    #   &lt;ENDPOINT&gt;SuccessFeedbackSampleRate attribute is for specifying
    #   the sample rate percentage (0-100) of successfully delivered messages.
    #   After you configure the &lt;ENDPOINT&gt;FailureFeedbackRoleArn
    #   attribute, then all failed message deliveries generate CloudWatch
    #   Logs.
    #
    #    </note>
    #
    #   The following attribute applies only to [server-side-encryption][2]:
    #
    #   * `KmsMasterKeyId` – The ID of an Amazon Web Services managed customer
    #     master key (CMK) for Amazon SNS or a custom CMK. For more
    #     information, see [Key Terms][3]. For more examples, see [KeyId][4]
    #     in the *Key Management Service API Reference*.
    #
    #   * `SignatureVersion` – The signature version corresponds to the
    #     hashing algorithm used while creating the signature of the
    #     notifications, subscription confirmations, or unsubscribe
    #     confirmation messages sent by Amazon SNS. By default,
    #     `SignatureVersion` is set to `1`.
    #
    #   The following attribute applies only to [FIFO topics][5]:
    #
    #   * `ContentBasedDeduplication` – Enables content-based deduplication
    #     for FIFO topics.
    #
    #     * By default, `ContentBasedDeduplication` is set to `false`. If you
    #       create a FIFO topic and this attribute is `false`, you must
    #       specify a value for the `MessageDeduplicationId` parameter for the
    #       [Publish][6] action.
    #
    #     * When you set `ContentBasedDeduplication` to `true`, Amazon SNS
    #       uses a SHA-256 hash to generate the `MessageDeduplicationId` using
    #       the body of the message (but not the attributes of the message).
    #
    #       (Optional) To override the generated value, you can specify a
    #       value for the `MessageDeduplicationId` parameter for the `Publish`
    #       action.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    #   [3]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    #   [4]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    #   [5]: https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html
    #   [6]: https://docs.aws.amazon.com/sns/latest/api/API_Publish.html
    # @option options [String] :attribute_value
    #   The new value for the attribute.
    # @return [EmptyStructure]
    def set_attributes(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.set_topic_attributes(options)
      end
      resp.data
    end

    # @example Request syntax with placeholder values
    #
    #   subscription = topic.subscribe({
    #     protocol: "protocol", # required
    #     endpoint: "endpoint",
    #     attributes: {
    #       "attributeName" => "attributeValue",
    #     },
    #     return_subscription_arn: false,
    #   })
    # @param [Hash] options ({})
    # @option options [required, String] :protocol
    #   The protocol that you want to use. Supported protocols include:
    #
    #   * `http` – delivery of JSON-encoded message via HTTP POST
    #
    #   * `https` – delivery of JSON-encoded message via HTTPS POST
    #
    #   * `email` – delivery of message via SMTP
    #
    #   * `email-json` – delivery of JSON-encoded message via SMTP
    #
    #   * `sms` – delivery of message via SMS
    #
    #   * `sqs` – delivery of JSON-encoded message to an Amazon SQS queue
    #
    #   * `application` – delivery of JSON-encoded message to an EndpointArn
    #     for a mobile app and device
    #
    #   * `lambda` – delivery of JSON-encoded message to an Lambda function
    #
    #   * `firehose` – delivery of JSON-encoded message to an Amazon Kinesis
    #     Data Firehose delivery stream.
    # @option options [String] :endpoint
    #   The endpoint that you want to receive notifications. Endpoints vary by
    #   protocol:
    #
    #   * For the `http` protocol, the (public) endpoint is a URL beginning
    #     with `http://`.
    #
    #   * For the `https` protocol, the (public) endpoint is a URL beginning
    #     with `https://`.
    #
    #   * For the `email` protocol, the endpoint is an email address.
    #
    #   * For the `email-json` protocol, the endpoint is an email address.
    #
    #   * For the `sms` protocol, the endpoint is a phone number of an
    #     SMS-enabled device.
    #
    #   * For the `sqs` protocol, the endpoint is the ARN of an Amazon SQS
    #     queue.
    #
    #   * For the `application` protocol, the endpoint is the EndpointArn of a
    #     mobile app and device.
    #
    #   * For the `lambda` protocol, the endpoint is the ARN of an Lambda
    #     function.
    #
    #   * For the `firehose` protocol, the endpoint is the ARN of an Amazon
    #     Kinesis Data Firehose delivery stream.
    # @option options [Hash<String,String>] :attributes
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the special
    #   request parameters that the `Subscribe` action uses:
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
    #   The following attributes apply only to [FIFO topics][2]:
    #
    #   * `ReplayPolicy` – Adds or updates an inline policy document for a
    #     subscription to replay messages stored in the specified Amazon SNS
    #     topic.
    #
    #   * `ReplayStatus` – Retrieves the status of the subscription message
    #     replay, which can be one of the following:
    #
    #     * `Completed` – The replay has successfully redelivered all
    #       messages, and is now delivering newly published messages. If an
    #       ending point was specified in the `ReplayPolicy` then the
    #       subscription will no longer receive newly published messages.
    #
    #     * `In progress` – The replay is currently replaying the selected
    #       messages.
    #
    #     * `Failed` – The replay was unable to complete.
    #
    #     * `Pending` – The default state while the replay initiates.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-firehose-as-subscriber.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html
    # @option options [Boolean] :return_subscription_arn
    #   Sets whether the response from the `Subscribe` request includes the
    #   subscription ARN, even if the subscription is not yet confirmed.
    #
    #   If you set this parameter to `true`, the response includes the ARN in
    #   all cases, even if the subscription is not yet confirmed. In addition
    #   to the ARN for confirmed subscriptions, the response also includes the
    #   `pending subscription` ARN value for subscriptions that aren't yet
    #   confirmed. A subscription becomes confirmed when the subscriber calls
    #   the `ConfirmSubscription` action with a confirmation token.
    #
    #
    #
    #   The default value is `false`.
    # @return [Subscription]
    def subscribe(options = {})
      options = options.merge(topic_arn: @arn)
      resp = Aws::Plugins::UserAgent.feature('resource') do
        @client.subscribe(options)
      end
      Subscription.new(
        arn: resp.data.subscription_arn,
        client: @client
      )
    end

    # @!group Associations

    # @example Request syntax with placeholder values
    #
    #   topic.subscriptions()
    # @param [Hash] options ({})
    # @return [Subscription::Collection]
    def subscriptions(options = {})
      batches = Enumerator.new do |y|
        options = options.merge(topic_arn: @arn)
        resp = Aws::Plugins::UserAgent.feature('resource') do
          @client.list_subscriptions_by_topic(options)
        end
        resp.each_page do |page|
          batch = []
          page.data.subscriptions.each do |s|
            batch << Subscription.new(
              arn: s.subscription_arn,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      Subscription::Collection.new(batches)
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
