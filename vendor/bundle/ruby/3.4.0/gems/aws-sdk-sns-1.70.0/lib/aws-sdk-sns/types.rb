# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::SNS
  module Types

    # @!attribute [rw] topic_arn
    #   The ARN of the topic whose access control policy you wish to modify.
    #   @return [String]
    #
    # @!attribute [rw] label
    #   A unique identifier for the new policy statement.
    #   @return [String]
    #
    # @!attribute [rw] aws_account_id
    #   The Amazon Web Services account IDs of the users (principals) who
    #   will be given access to the specified actions. The users must have
    #   Amazon Web Services account, but do not need to be signed up for
    #   this service.
    #   @return [Array<String>]
    #
    # @!attribute [rw] action_name
    #   The action you want to allow for the specified principal(s).
    #
    #   Valid values: Any Amazon SNS action name, for example `Publish`.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/AddPermissionInput AWS API Documentation
    #
    class AddPermissionInput < Struct.new(
      :topic_arn,
      :label,
      :aws_account_id,
      :action_name)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the user has been denied access to the requested
    # resource.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/AuthorizationErrorException AWS API Documentation
    #
    class AuthorizationErrorException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Two or more batch entries in the request have the same `Id`.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/BatchEntryIdsNotDistinctException AWS API Documentation
    #
    class BatchEntryIdsNotDistinctException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The length of all the batch messages put together is more than the
    # limit.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/BatchRequestTooLongException AWS API Documentation
    #
    class BatchRequestTooLongException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Gives a detailed description of failed messages in the batch.
    #
    # @!attribute [rw] id
    #   The `Id` of an entry in a batch request
    #   @return [String]
    #
    # @!attribute [rw] code
    #   An error code representing why the action failed on this entry.
    #   @return [String]
    #
    # @!attribute [rw] message
    #   A message explaining why the action failed on this entry.
    #   @return [String]
    #
    # @!attribute [rw] sender_fault
    #   Specifies whether the error happened due to the caller of the batch
    #   API action.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/BatchResultErrorEntry AWS API Documentation
    #
    class BatchResultErrorEntry < Struct.new(
      :id,
      :code,
      :message,
      :sender_fault)
      SENSITIVE = []
      include Aws::Structure
    end

    # The input for the `CheckIfPhoneNumberIsOptedOut` action.
    #
    # @!attribute [rw] phone_number
    #   The phone number for which you want to check the opt out status.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CheckIfPhoneNumberIsOptedOutInput AWS API Documentation
    #
    class CheckIfPhoneNumberIsOptedOutInput < Struct.new(
      :phone_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # The response from the `CheckIfPhoneNumberIsOptedOut` action.
    #
    # @!attribute [rw] is_opted_out
    #   Indicates whether the phone number is opted out:
    #
    #   * `true` – The phone number is opted out, meaning you cannot publish
    #     SMS messages to it.
    #
    #   * `false` – The phone number is opted in, meaning you can publish
    #     SMS messages to it.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CheckIfPhoneNumberIsOptedOutResponse AWS API Documentation
    #
    class CheckIfPhoneNumberIsOptedOutResponse < Struct.new(
      :is_opted_out)
      SENSITIVE = []
      include Aws::Structure
    end

    # Can't perform multiple operations on a tag simultaneously. Perform
    # the operations sequentially.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ConcurrentAccessException AWS API Documentation
    #
    class ConcurrentAccessException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for ConfirmSubscription action.
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the topic for which you wish to confirm a subscription.
    #   @return [String]
    #
    # @!attribute [rw] token
    #   Short-lived token sent to an endpoint during the `Subscribe` action.
    #   @return [String]
    #
    # @!attribute [rw] authenticate_on_unsubscribe
    #   Disallows unauthenticated unsubscribes of the subscription. If the
    #   value of this parameter is `true` and the request has an Amazon Web
    #   Services signature, then only the topic owner and the subscription
    #   owner can unsubscribe the endpoint. The unsubscribe action requires
    #   Amazon Web Services authentication.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ConfirmSubscriptionInput AWS API Documentation
    #
    class ConfirmSubscriptionInput < Struct.new(
      :topic_arn,
      :token,
      :authenticate_on_unsubscribe)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for ConfirmSubscriptions action.
    #
    # @!attribute [rw] subscription_arn
    #   The ARN of the created subscription.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ConfirmSubscriptionResponse AWS API Documentation
    #
    class ConfirmSubscriptionResponse < Struct.new(
      :subscription_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response from CreateEndpoint action.
    #
    # @!attribute [rw] endpoint_arn
    #   EndpointArn returned from CreateEndpoint action.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreateEndpointResponse AWS API Documentation
    #
    class CreateEndpointResponse < Struct.new(
      :endpoint_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for CreatePlatformApplication action.
    #
    # @!attribute [rw] name
    #   Application names must be made up of only uppercase and lowercase
    #   ASCII letters, numbers, underscores, hyphens, and periods, and must
    #   be between 1 and 256 characters long.
    #   @return [String]
    #
    # @!attribute [rw] platform
    #   The following platforms are supported: ADM (Amazon Device
    #   Messaging), APNS (Apple Push Notification Service), APNS\_SANDBOX,
    #   and GCM (Firebase Cloud Messaging).
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   For a list of attributes, see [SetPlatformApplicationAttributes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetPlatformApplicationAttributes.html
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreatePlatformApplicationInput AWS API Documentation
    #
    class CreatePlatformApplicationInput < Struct.new(
      :name,
      :platform,
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response from CreatePlatformApplication action.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn is returned.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreatePlatformApplicationResponse AWS API Documentation
    #
    class CreatePlatformApplicationResponse < Struct.new(
      :platform_application_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for CreatePlatformEndpoint action.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn returned from CreatePlatformApplication is
    #   used to create a an endpoint.
    #   @return [String]
    #
    # @!attribute [rw] token
    #   Unique identifier created by the notification service for an app on
    #   a device. The specific name for Token will vary, depending on which
    #   notification service is being used. For example, when using APNS as
    #   the notification service, you need the device token. Alternatively,
    #   when using GCM (Firebase Cloud Messaging) or ADM, the device token
    #   equivalent is called the registration ID.
    #   @return [String]
    #
    # @!attribute [rw] custom_user_data
    #   Arbitrary user data to associate with the endpoint. Amazon SNS does
    #   not use this data. The data must be in UTF-8 format and less than
    #   2KB.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   For a list of attributes, see [SetEndpointAttributes][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetEndpointAttributes.html
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreatePlatformEndpointInput AWS API Documentation
    #
    class CreatePlatformEndpointInput < Struct.new(
      :platform_application_arn,
      :token,
      :custom_user_data,
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] phone_number
    #   The destination phone number to verify. On verification, Amazon SNS
    #   adds this phone number to the list of verified phone numbers that
    #   you can send SMS messages to.
    #   @return [String]
    #
    # @!attribute [rw] language_code
    #   The language to use for sending the OTP. The default value is
    #   `en-US`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreateSMSSandboxPhoneNumberInput AWS API Documentation
    #
    class CreateSMSSandboxPhoneNumberInput < Struct.new(
      :phone_number,
      :language_code)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreateSMSSandboxPhoneNumberResult AWS API Documentation
    #
    class CreateSMSSandboxPhoneNumberResult < Aws::EmptyStructure; end

    # Input for CreateTopic action.
    #
    # @!attribute [rw] name
    #   The name of the topic you want to create.
    #
    #   Constraints: Topic names must be made up of only uppercase and
    #   lowercase ASCII letters, numbers, underscores, and hyphens, and must
    #   be between 1 and 256 characters long.
    #
    #   For a FIFO (first-in-first-out) topic, the name must end with the
    #   `.fifo` suffix.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the
    #   special request parameters that the `CreateTopic` action uses:
    #
    #   * `DeliveryPolicy` – The policy that defines how Amazon SNS retries
    #     failed deliveries to HTTP/S endpoints.
    #
    #   * `DisplayName` – The display name to use for a topic with SMS
    #     subscriptions.
    #
    #   * `FifoTopic` – Set to true to create a FIFO topic.
    #
    #   * `Policy` – The policy that defines who can access your topic. By
    #     default, only the topic owner can publish or subscribe to the
    #     topic.
    #
    #   * `SignatureVersion` – The signature version corresponds to the
    #     hashing algorithm used while creating the signature of the
    #     notifications, subscription confirmations, or unsubscribe
    #     confirmation messages sent by Amazon SNS. By default,
    #     `SignatureVersion` is set to `1`.
    #
    #   * `TracingConfig` – Tracing mode of an Amazon SNS topic. By default
    #     `TracingConfig` is set to `PassThrough`, and the topic passes
    #     through the tracing header it receives from an Amazon SNS
    #     publisher to its subscriptions. If set to `Active`, Amazon SNS
    #     will vend X-Ray segment data to topic owner account if the sampled
    #     flag in the tracing header is true. This is only supported on
    #     standard topics.
    #
    #   The following attribute applies only to [server-side encryption][1]:
    #
    #   * `KmsMasterKeyId` – The ID of an Amazon Web Services managed
    #     customer master key (CMK) for Amazon SNS or a custom CMK. For more
    #     information, see [Key Terms][2]. For more examples, see [KeyId][3]
    #     in the *Key Management Service API Reference*.
    #
    #   ^
    #
    #   The following attributes apply only to [FIFO topics][4]:
    #
    #   * `ArchivePolicy` – Adds or updates an inline policy document to
    #     archive messages stored in the specified Amazon SNS topic.
    #
    #   * `BeginningArchiveTime` – The earliest starting point at which a
    #     message in the topic’s archive can be replayed from. This point in
    #     time is based on the configured message retention period set by
    #     the topic’s message archiving policy.
    #
    #   * `ContentBasedDeduplication` – Enables content-based deduplication
    #     for FIFO topics.
    #
    #     * By default, `ContentBasedDeduplication` is set to `false`. If
    #       you create a FIFO topic and this attribute is `false`, you must
    #       specify a value for the `MessageDeduplicationId` parameter for
    #       the [Publish][5] action.
    #
    #     * When you set `ContentBasedDeduplication` to `true`, Amazon SNS
    #       uses a SHA-256 hash to generate the `MessageDeduplicationId`
    #       using the body of the message (but not the attributes of the
    #       message).
    #
    #       (Optional) To override the generated value, you can specify a
    #       value for the `MessageDeduplicationId` parameter for the
    #       `Publish` action.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    #   [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    #   [4]: https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html
    #   [5]: https://docs.aws.amazon.com/sns/latest/api/API_Publish.html
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] tags
    #   The list of tags to add to a new topic.
    #
    #   <note markdown="1"> To be able to tag a topic on creation, you must have the
    #   `sns:CreateTopic` and `sns:TagResource` permissions.
    #
    #    </note>
    #   @return [Array<Types::Tag>]
    #
    # @!attribute [rw] data_protection_policy
    #   The body of the policy document you want to use for this topic.
    #
    #   You can only add one policy per topic.
    #
    #   The policy must be in JSON string format.
    #
    #   Length Constraints: Maximum length of 30,720.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreateTopicInput AWS API Documentation
    #
    class CreateTopicInput < Struct.new(
      :name,
      :attributes,
      :tags,
      :data_protection_policy)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response from CreateTopic action.
    #
    # @!attribute [rw] topic_arn
    #   The Amazon Resource Name (ARN) assigned to the created topic.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/CreateTopicResponse AWS API Documentation
    #
    class CreateTopicResponse < Struct.new(
      :topic_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for DeleteEndpoint action.
    #
    # @!attribute [rw] endpoint_arn
    #   EndpointArn of endpoint to delete.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeleteEndpointInput AWS API Documentation
    #
    class DeleteEndpointInput < Struct.new(
      :endpoint_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for DeletePlatformApplication action.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn of platform application object to delete.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeletePlatformApplicationInput AWS API Documentation
    #
    class DeletePlatformApplicationInput < Struct.new(
      :platform_application_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] phone_number
    #   The destination phone number to delete.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeleteSMSSandboxPhoneNumberInput AWS API Documentation
    #
    class DeleteSMSSandboxPhoneNumberInput < Struct.new(
      :phone_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeleteSMSSandboxPhoneNumberResult AWS API Documentation
    #
    class DeleteSMSSandboxPhoneNumberResult < Aws::EmptyStructure; end

    # @!attribute [rw] topic_arn
    #   The ARN of the topic you want to delete.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/DeleteTopicInput AWS API Documentation
    #
    class DeleteTopicInput < Struct.new(
      :topic_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # The batch request doesn't contain any entries.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/EmptyBatchRequestException AWS API Documentation
    #
    class EmptyBatchRequestException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The endpoint for mobile app and device.
    #
    # @!attribute [rw] endpoint_arn
    #   The `EndpointArn` for mobile app and device.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   Attributes for endpoint.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Endpoint AWS API Documentation
    #
    class Endpoint < Struct.new(
      :endpoint_arn,
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Exception error indicating endpoint disabled.
    #
    # @!attribute [rw] message
    #   Message for endpoint disabled.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/EndpointDisabledException AWS API Documentation
    #
    class EndpointDisabledException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the number of filter polices in your Amazon Web
    # Services account exceeds the limit. To add more filter polices, submit
    # an Amazon SNS Limit Increase case in the Amazon Web Services Support
    # Center.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/FilterPolicyLimitExceededException AWS API Documentation
    #
    class FilterPolicyLimitExceededException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] resource_arn
    #   The ARN of the topic whose `DataProtectionPolicy` you want to get.
    #
    #   For more information about ARNs, see [Amazon Resource Names
    #   (ARNs)][1] in the Amazon Web Services General Reference.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetDataProtectionPolicyInput AWS API Documentation
    #
    class GetDataProtectionPolicyInput < Struct.new(
      :resource_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] data_protection_policy
    #   Retrieves the `DataProtectionPolicy` in JSON string format.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetDataProtectionPolicyResponse AWS API Documentation
    #
    class GetDataProtectionPolicyResponse < Struct.new(
      :data_protection_policy)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for GetEndpointAttributes action.
    #
    # @!attribute [rw] endpoint_arn
    #   EndpointArn for GetEndpointAttributes input.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetEndpointAttributesInput AWS API Documentation
    #
    class GetEndpointAttributesInput < Struct.new(
      :endpoint_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response from GetEndpointAttributes of the EndpointArn.
    #
    # @!attribute [rw] attributes
    #   Attributes include the following:
    #
    #   * `CustomUserData` – arbitrary user data to associate with the
    #     endpoint. Amazon SNS does not use this data. The data must be in
    #     UTF-8 format and less than 2KB.
    #
    #   * `Enabled` – flag that enables/disables delivery to the endpoint.
    #     Amazon SNS will set this to false when a notification service
    #     indicates to Amazon SNS that the endpoint is invalid. Users can
    #     set it back to true, typically after updating Token.
    #
    #   * `Token` – device token, also referred to as a registration id, for
    #     an app and mobile device. This is returned from the notification
    #     service when an app and mobile device are registered with the
    #     notification service.
    #
    #     <note markdown="1"> The device token for the iOS platform is returned in lowercase.
    #
    #      </note>
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetEndpointAttributesResponse AWS API Documentation
    #
    class GetEndpointAttributesResponse < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for GetPlatformApplicationAttributes action.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn for GetPlatformApplicationAttributesInput.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetPlatformApplicationAttributesInput AWS API Documentation
    #
    class GetPlatformApplicationAttributesInput < Struct.new(
      :platform_application_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for GetPlatformApplicationAttributes action.
    #
    # @!attribute [rw] attributes
    #   Attributes include the following:
    #
    #   * `AppleCertificateExpiryDate` – The expiry date of the SSL
    #     certificate used to configure certificate-based authentication.
    #
    #   * `ApplePlatformTeamID` – The Apple developer account ID used to
    #     configure token-based authentication.
    #
    #   * `ApplePlatformBundleID` – The app identifier used to configure
    #     token-based authentication.
    #
    #   * `EventEndpointCreated` – Topic ARN to which EndpointCreated event
    #     notifications should be sent.
    #
    #   * `EventEndpointDeleted` – Topic ARN to which EndpointDeleted event
    #     notifications should be sent.
    #
    #   * `EventEndpointUpdated` – Topic ARN to which EndpointUpdate event
    #     notifications should be sent.
    #
    #   * `EventDeliveryFailure` – Topic ARN to which DeliveryFailure event
    #     notifications should be sent upon Direct Publish delivery failure
    #     (permanent) to one of the application's endpoints.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetPlatformApplicationAttributesResponse AWS API Documentation
    #
    class GetPlatformApplicationAttributesResponse < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # The input for the `GetSMSAttributes` request.
    #
    # @!attribute [rw] attributes
    #   A list of the individual attribute names, such as
    #   `MonthlySpendLimit`, for which you want values.
    #
    #   For all attribute names, see [SetSMSAttributes][1].
    #
    #   If you don't use this parameter, Amazon SNS returns all SMS
    #   attributes.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/api/API_SetSMSAttributes.html
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSMSAttributesInput AWS API Documentation
    #
    class GetSMSAttributesInput < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # The response from the `GetSMSAttributes` request.
    #
    # @!attribute [rw] attributes
    #   The SMS attribute names and their values.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSMSAttributesResponse AWS API Documentation
    #
    class GetSMSAttributesResponse < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSMSSandboxAccountStatusInput AWS API Documentation
    #
    class GetSMSSandboxAccountStatusInput < Aws::EmptyStructure; end

    # @!attribute [rw] is_in_sandbox
    #   Indicates whether the calling Amazon Web Services account is in the
    #   SMS sandbox.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSMSSandboxAccountStatusResult AWS API Documentation
    #
    class GetSMSSandboxAccountStatusResult < Struct.new(
      :is_in_sandbox)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for GetSubscriptionAttributes.
    #
    # @!attribute [rw] subscription_arn
    #   The ARN of the subscription whose properties you want to get.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSubscriptionAttributesInput AWS API Documentation
    #
    class GetSubscriptionAttributesInput < Struct.new(
      :subscription_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for GetSubscriptionAttributes action.
    #
    # @!attribute [rw] attributes
    #   A map of the subscription's attributes. Attributes in this map
    #   include the following:
    #
    #   * `ConfirmationWasAuthenticated` – `true` if the subscription
    #     confirmation request was authenticated.
    #
    #   * `DeliveryPolicy` – The JSON serialization of the subscription's
    #     delivery policy.
    #
    #   * `EffectiveDeliveryPolicy` – The JSON serialization of the
    #     effective delivery policy that takes into account the topic
    #     delivery policy and account system defaults.
    #
    #   * `FilterPolicy` – The filter policy JSON that is assigned to the
    #     subscription. For more information, see [Amazon SNS Message
    #     Filtering][1] in the *Amazon SNS Developer Guide*.
    #
    #   * `FilterPolicyScope` – This attribute lets you choose the filtering
    #     scope by using one of the following string value types:
    #
    #     * `MessageAttributes` (default) – The filter is applied on the
    #       message attributes.
    #
    #     * `MessageBody` – The filter is applied on the message body.
    #
    #   * `Owner` – The Amazon Web Services account ID of the
    #     subscription's owner.
    #
    #   * `PendingConfirmation` – `true` if the subscription hasn't been
    #     confirmed. To confirm a pending subscription, call the
    #     `ConfirmSubscription` action with a confirmation token.
    #
    #   * `RawMessageDelivery` – `true` if raw message delivery is enabled
    #     for the subscription. Raw messages are free of JSON formatting and
    #     can be sent to HTTP/S and Amazon SQS endpoints.
    #
    #   * `RedrivePolicy` – When specified, sends undeliverable messages to
    #     the specified Amazon SQS dead-letter queue. Messages that can't
    #     be delivered due to client errors (for example, when the
    #     subscribed endpoint is unreachable) or server errors (for example,
    #     when the service that powers the subscribed endpoint becomes
    #     unavailable) are held in the dead-letter queue for further
    #     analysis or reprocessing.
    #
    #   * `SubscriptionArn` – The subscription's ARN.
    #
    #   * `TopicArn` – The topic ARN that the subscription is associated
    #     with.
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
    #     see [Fanout to Kinesis Data Firehose delivery streams][2] in the
    #     *Amazon SNS Developer Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-message-filtering.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-firehose-as-subscriber.html
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetSubscriptionAttributesResponse AWS API Documentation
    #
    class GetSubscriptionAttributesResponse < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for GetTopicAttributes action.
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the topic whose properties you want to get.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetTopicAttributesInput AWS API Documentation
    #
    class GetTopicAttributesInput < Struct.new(
      :topic_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for GetTopicAttributes action.
    #
    # @!attribute [rw] attributes
    #   A map of the topic's attributes. Attributes in this map include the
    #   following:
    #
    #   * `DeliveryPolicy` – The JSON serialization of the topic's delivery
    #     policy.
    #
    #   * `DisplayName` – The human-readable name used in the `From` field
    #     for notifications to `email` and `email-json` endpoints.
    #
    #   * `EffectiveDeliveryPolicy` – The JSON serialization of the
    #     effective delivery policy, taking system defaults into account.
    #
    #   * `Owner` – The Amazon Web Services account ID of the topic's
    #     owner.
    #
    #   * `Policy` – The JSON serialization of the topic's access control
    #     policy.
    #
    #   * `SignatureVersion` – The signature version corresponds to the
    #     hashing algorithm used while creating the signature of the
    #     notifications, subscription confirmations, or unsubscribe
    #     confirmation messages sent by Amazon SNS.
    #
    #     * By default, `SignatureVersion` is set to **1**. The signature is
    #       a Base64-encoded **SHA1withRSA** signature.
    #
    #     * When you set `SignatureVersion` to **2**. Amazon SNS uses a
    #       Base64-encoded **SHA256withRSA** signature.
    #
    #       <note markdown="1"> If the API response does not include the `SignatureVersion`
    #       attribute, it means that the `SignatureVersion` for the topic
    #       has value **1**.
    #
    #        </note>
    #
    #   * `SubscriptionsConfirmed` – The number of confirmed subscriptions
    #     for the topic.
    #
    #   * `SubscriptionsDeleted` – The number of deleted subscriptions for
    #     the topic.
    #
    #   * `SubscriptionsPending` – The number of subscriptions pending
    #     confirmation for the topic.
    #
    #   * `TopicArn` – The topic's ARN.
    #
    #   * `TracingConfig` – Tracing mode of an Amazon SNS topic. By default
    #     `TracingConfig` is set to `PassThrough`, and the topic passes
    #     through the tracing header it receives from an Amazon SNS
    #     publisher to its subscriptions. If set to `Active`, Amazon SNS
    #     will vend X-Ray segment data to topic owner account if the sampled
    #     flag in the tracing header is true. This is only supported on
    #     standard topics.
    #
    #   The following attribute applies only to [server-side-encryption][1]:
    #
    #   * `KmsMasterKeyId` - The ID of an Amazon Web Services managed
    #     customer master key (CMK) for Amazon SNS or a custom CMK. For more
    #     information, see [Key Terms][2]. For more examples, see [KeyId][3]
    #     in the *Key Management Service API Reference*.
    #
    #   ^
    #
    #   The following attributes apply only to [FIFO topics][4]:
    #
    #   * `FifoTopic` – When this is set to `true`, a FIFO topic is created.
    #
    #   * `ContentBasedDeduplication` – Enables content-based deduplication
    #     for FIFO topics.
    #
    #     * By default, `ContentBasedDeduplication` is set to `false`. If
    #       you create a FIFO topic and this attribute is `false`, you must
    #       specify a value for the `MessageDeduplicationId` parameter for
    #       the [Publish][5] action.
    #
    #     * When you set `ContentBasedDeduplication` to `true`, Amazon SNS
    #       uses a SHA-256 hash to generate the `MessageDeduplicationId`
    #       using the body of the message (but not the attributes of the
    #       message).
    #
    #       (Optional) To override the generated value, you can specify a
    #       value for the `MessageDeduplicationId` parameter for the
    #       `Publish` action.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    #   [3]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    #   [4]: https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html
    #   [5]: https://docs.aws.amazon.com/sns/latest/api/API_Publish.html
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/GetTopicAttributesResponse AWS API Documentation
    #
    class GetTopicAttributesResponse < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates an internal service error.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/InternalErrorException AWS API Documentation
    #
    class InternalErrorException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The `Id` of a batch entry in a batch request doesn't abide by the
    # specification.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/InvalidBatchEntryIdException AWS API Documentation
    #
    class InvalidBatchEntryIdException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a request parameter does not comply with the associated
    # constraints.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/InvalidParameterException AWS API Documentation
    #
    class InvalidParameterException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a request parameter does not comply with the associated
    # constraints.
    #
    # @!attribute [rw] message
    #   The parameter of an entry in a request doesn't abide by the
    #   specification.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/InvalidParameterValueException AWS API Documentation
    #
    class InvalidParameterValueException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The credential signature isn't valid. You must use an HTTPS endpoint
    # and sign your request using Signature Version 4.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/InvalidSecurityException AWS API Documentation
    #
    class InvalidSecurityException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the specified state is not a valid state for an event
    # source.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/InvalidStateException AWS API Documentation
    #
    class InvalidStateException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The ciphertext references a key that doesn't exist or that you don't
    # have access to.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/KMSAccessDeniedException AWS API Documentation
    #
    class KMSAccessDeniedException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request was rejected because the specified Amazon Web Services KMS
    # key isn't enabled.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/KMSDisabledException AWS API Documentation
    #
    class KMSDisabledException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request was rejected because the state of the specified resource
    # isn't valid for this request. For more information, see [Key states
    # of Amazon Web Services KMS keys][1] in the *Key Management Service
    # Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/key-state.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/KMSInvalidStateException AWS API Documentation
    #
    class KMSInvalidStateException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request was rejected because the specified entity or resource
    # can't be found.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/KMSNotFoundException AWS API Documentation
    #
    class KMSNotFoundException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The Amazon Web Services access key ID needs a subscription for the
    # service.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/KMSOptInRequired AWS API Documentation
    #
    class KMSOptInRequired < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request was denied due to request throttling. For more information
    # about throttling, see [Limits][1] in the *Key Management Service
    # Developer Guide.*
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/kms/latest/developerguide/limits.html#requests-per-second
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/KMSThrottlingException AWS API Documentation
    #
    class KMSThrottlingException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for ListEndpointsByPlatformApplication action.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn for ListEndpointsByPlatformApplicationInput
    #   action.
    #   @return [String]
    #
    # @!attribute [rw] next_token
    #   NextToken string is used when calling
    #   ListEndpointsByPlatformApplication action to retrieve additional
    #   records that are available after the first page results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListEndpointsByPlatformApplicationInput AWS API Documentation
    #
    class ListEndpointsByPlatformApplicationInput < Struct.new(
      :platform_application_arn,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for ListEndpointsByPlatformApplication action.
    #
    # @!attribute [rw] endpoints
    #   Endpoints returned for ListEndpointsByPlatformApplication action.
    #   @return [Array<Types::Endpoint>]
    #
    # @!attribute [rw] next_token
    #   NextToken string is returned when calling
    #   ListEndpointsByPlatformApplication action if additional records are
    #   available after the first page results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListEndpointsByPlatformApplicationResponse AWS API Documentation
    #
    class ListEndpointsByPlatformApplicationResponse < Struct.new(
      :endpoints,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   Token that the previous `ListOriginationNumbers` request returns.
    #   @return [String]
    #
    # @!attribute [rw] max_results
    #   The maximum number of origination numbers to return.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListOriginationNumbersRequest AWS API Documentation
    #
    class ListOriginationNumbersRequest < Struct.new(
      :next_token,
      :max_results)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   A `NextToken` string is returned when you call the
    #   `ListOriginationNumbers` operation if additional pages of records
    #   are available.
    #   @return [String]
    #
    # @!attribute [rw] phone_numbers
    #   A list of the calling account's verified and pending origination
    #   numbers.
    #   @return [Array<Types::PhoneNumberInformation>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListOriginationNumbersResult AWS API Documentation
    #
    class ListOriginationNumbersResult < Struct.new(
      :next_token,
      :phone_numbers)
      SENSITIVE = []
      include Aws::Structure
    end

    # The input for the `ListPhoneNumbersOptedOut` action.
    #
    # @!attribute [rw] next_token
    #   A `NextToken` string is used when you call the
    #   `ListPhoneNumbersOptedOut` action to retrieve additional records
    #   that are available after the first page of results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListPhoneNumbersOptedOutInput AWS API Documentation
    #
    class ListPhoneNumbersOptedOutInput < Struct.new(
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # The response from the `ListPhoneNumbersOptedOut` action.
    #
    # @!attribute [rw] phone_numbers
    #   A list of phone numbers that are opted out of receiving SMS
    #   messages. The list is paginated, and each page can contain up to 100
    #   phone numbers.
    #   @return [Array<String>]
    #
    # @!attribute [rw] next_token
    #   A `NextToken` string is returned when you call the
    #   `ListPhoneNumbersOptedOut` action if additional records are
    #   available after the first page of results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListPhoneNumbersOptedOutResponse AWS API Documentation
    #
    class ListPhoneNumbersOptedOutResponse < Struct.new(
      :phone_numbers,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for ListPlatformApplications action.
    #
    # @!attribute [rw] next_token
    #   NextToken string is used when calling ListPlatformApplications
    #   action to retrieve additional records that are available after the
    #   first page results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListPlatformApplicationsInput AWS API Documentation
    #
    class ListPlatformApplicationsInput < Struct.new(
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for ListPlatformApplications action.
    #
    # @!attribute [rw] platform_applications
    #   Platform applications returned when calling ListPlatformApplications
    #   action.
    #   @return [Array<Types::PlatformApplication>]
    #
    # @!attribute [rw] next_token
    #   NextToken string is returned when calling ListPlatformApplications
    #   action if additional records are available after the first page
    #   results.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListPlatformApplicationsResponse AWS API Documentation
    #
    class ListPlatformApplicationsResponse < Struct.new(
      :platform_applications,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   Token that the previous `ListSMSSandboxPhoneNumbersInput` request
    #   returns.
    #   @return [String]
    #
    # @!attribute [rw] max_results
    #   The maximum number of phone numbers to return.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSMSSandboxPhoneNumbersInput AWS API Documentation
    #
    class ListSMSSandboxPhoneNumbersInput < Struct.new(
      :next_token,
      :max_results)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] phone_numbers
    #   A list of the calling account's pending and verified phone numbers.
    #   @return [Array<Types::SMSSandboxPhoneNumber>]
    #
    # @!attribute [rw] next_token
    #   A `NextToken` string is returned when you call the
    #   `ListSMSSandboxPhoneNumbersInput` operation if additional pages of
    #   records are available.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSMSSandboxPhoneNumbersResult AWS API Documentation
    #
    class ListSMSSandboxPhoneNumbersResult < Struct.new(
      :phone_numbers,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for ListSubscriptionsByTopic action.
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the topic for which you wish to find subscriptions.
    #   @return [String]
    #
    # @!attribute [rw] next_token
    #   Token returned by the previous `ListSubscriptionsByTopic` request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSubscriptionsByTopicInput AWS API Documentation
    #
    class ListSubscriptionsByTopicInput < Struct.new(
      :topic_arn,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for ListSubscriptionsByTopic action.
    #
    # @!attribute [rw] subscriptions
    #   A list of subscriptions.
    #   @return [Array<Types::Subscription>]
    #
    # @!attribute [rw] next_token
    #   Token to pass along to the next `ListSubscriptionsByTopic` request.
    #   This element is returned if there are more subscriptions to
    #   retrieve.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSubscriptionsByTopicResponse AWS API Documentation
    #
    class ListSubscriptionsByTopicResponse < Struct.new(
      :subscriptions,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for ListSubscriptions action.
    #
    # @!attribute [rw] next_token
    #   Token returned by the previous `ListSubscriptions` request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSubscriptionsInput AWS API Documentation
    #
    class ListSubscriptionsInput < Struct.new(
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for ListSubscriptions action
    #
    # @!attribute [rw] subscriptions
    #   A list of subscriptions.
    #   @return [Array<Types::Subscription>]
    #
    # @!attribute [rw] next_token
    #   Token to pass along to the next `ListSubscriptions` request. This
    #   element is returned if there are more subscriptions to retrieve.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListSubscriptionsResponse AWS API Documentation
    #
    class ListSubscriptionsResponse < Struct.new(
      :subscriptions,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] resource_arn
    #   The ARN of the topic for which to list tags.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListTagsForResourceRequest AWS API Documentation
    #
    class ListTagsForResourceRequest < Struct.new(
      :resource_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] tags
    #   The tags associated with the specified topic.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListTagsForResourceResponse AWS API Documentation
    #
    class ListTagsForResourceResponse < Struct.new(
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] next_token
    #   Token returned by the previous `ListTopics` request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListTopicsInput AWS API Documentation
    #
    class ListTopicsInput < Struct.new(
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for ListTopics action.
    #
    # @!attribute [rw] topics
    #   A list of topic ARNs.
    #   @return [Array<Types::Topic>]
    #
    # @!attribute [rw] next_token
    #   Token to pass along to the next `ListTopics` request. This element
    #   is returned if there are additional topics to retrieve.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ListTopicsResponse AWS API Documentation
    #
    class ListTopicsResponse < Struct.new(
      :topics,
      :next_token)
      SENSITIVE = []
      include Aws::Structure
    end

    # The user-specified message attribute value. For string data types, the
    # value attribute has the same restrictions on the content as the
    # message body. For more information, see [Publish][1].
    #
    # Name, type, and value must not be empty or null. In addition, the
    # message body should not be empty or null. All parts of the message
    # attribute, including name, type, and value, are included in the
    # message size restriction, which is currently 256 KB (262,144 bytes).
    # For more information, see [Amazon SNS message attributes][2] and
    # [Publishing to a mobile phone][3] in the *Amazon SNS Developer Guide.*
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/api/API_Publish.html
    # [2]: https://docs.aws.amazon.com/sns/latest/dg/SNSMessageAttributes.html
    # [3]: https://docs.aws.amazon.com/sns/latest/dg/sms_publish-to-phone.html
    #
    # @!attribute [rw] data_type
    #   Amazon SNS supports the following logical data types: String,
    #   String.Array, Number, and Binary. For more information, see [Message
    #   Attribute Data Types][1].
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/SNSMessageAttributes.html#SNSMessageAttributes.DataTypes
    #   @return [String]
    #
    # @!attribute [rw] string_value
    #   Strings are Unicode with UTF8 binary encoding. For a list of code
    #   values, see [ASCII Printable Characters][1].
    #
    #
    #
    #   [1]: https://en.wikipedia.org/wiki/ASCII#ASCII_printable_characters
    #   @return [String]
    #
    # @!attribute [rw] binary_value
    #   Binary type attributes can store any binary data, for example,
    #   compressed data, encrypted data, or images.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/MessageAttributeValue AWS API Documentation
    #
    class MessageAttributeValue < Struct.new(
      :data_type,
      :string_value,
      :binary_value)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the requested resource does not exist.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/NotFoundException AWS API Documentation
    #
    class NotFoundException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for the OptInPhoneNumber action.
    #
    # @!attribute [rw] phone_number
    #   The phone number to opt in. Use E.164 format.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/OptInPhoneNumberInput AWS API Documentation
    #
    class OptInPhoneNumberInput < Struct.new(
      :phone_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # The response for the OptInPhoneNumber action.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/OptInPhoneNumberResponse AWS API Documentation
    #
    class OptInPhoneNumberResponse < Aws::EmptyStructure; end

    # Indicates that the specified phone number opted out of receiving SMS
    # messages from your Amazon Web Services account. You can't send SMS
    # messages to phone numbers that opt out.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/OptedOutException AWS API Documentation
    #
    class OptedOutException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # A list of phone numbers and their metadata.
    #
    # @!attribute [rw] created_at
    #   The date and time when the phone number was created.
    #   @return [Time]
    #
    # @!attribute [rw] phone_number
    #   The phone number.
    #   @return [String]
    #
    # @!attribute [rw] status
    #   The status of the phone number.
    #   @return [String]
    #
    # @!attribute [rw] iso_2_country_code
    #   The two-character code for the country or region, in ISO 3166-1
    #   alpha-2 format.
    #   @return [String]
    #
    # @!attribute [rw] route_type
    #   The list of supported routes.
    #   @return [String]
    #
    # @!attribute [rw] number_capabilities
    #   The capabilities of each phone number.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PhoneNumberInformation AWS API Documentation
    #
    class PhoneNumberInformation < Struct.new(
      :created_at,
      :phone_number,
      :status,
      :iso_2_country_code,
      :route_type,
      :number_capabilities)
      SENSITIVE = []
      include Aws::Structure
    end

    # Platform application object.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn for platform application object.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   Attributes for platform application object.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PlatformApplication AWS API Documentation
    #
    class PlatformApplication < Struct.new(
      :platform_application_arn,
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Exception error indicating platform application disabled.
    #
    # @!attribute [rw] message
    #   Message for platform application disabled.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PlatformApplicationDisabledException AWS API Documentation
    #
    class PlatformApplicationDisabledException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] topic_arn
    #   The Amazon resource name (ARN) of the topic you want to batch
    #   publish to.
    #   @return [String]
    #
    # @!attribute [rw] publish_batch_request_entries
    #   A list of `PublishBatch` request entries to be sent to the SNS
    #   topic.
    #   @return [Array<Types::PublishBatchRequestEntry>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PublishBatchInput AWS API Documentation
    #
    class PublishBatchInput < Struct.new(
      :topic_arn,
      :publish_batch_request_entries)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the details of a single Amazon SNS message along with an `Id`
    # that identifies a message within the batch.
    #
    # @!attribute [rw] id
    #   An identifier for the message in this batch.
    #
    #   <note markdown="1"> The `Ids` of a batch request must be unique within a request.
    #
    #    This identifier can have up to 80 characters. The following
    #   characters are accepted: alphanumeric characters, hyphens(-), and
    #   underscores (\_).
    #
    #    </note>
    #   @return [String]
    #
    # @!attribute [rw] message
    #   The body of the message.
    #   @return [String]
    #
    # @!attribute [rw] subject
    #   The subject of the batch message.
    #   @return [String]
    #
    # @!attribute [rw] message_structure
    #   Set `MessageStructure` to `json` if you want to send a different
    #   message for each protocol. For example, using one publish action,
    #   you can send a short message to your SMS subscribers and a longer
    #   message to your email subscribers. If you set `MessageStructure` to
    #   `json`, the value of the `Message` parameter must:
    #
    #   * be a syntactically valid JSON object; and
    #
    #   * contain at least a top-level JSON key of "default" with a value
    #     that is a string.
    #
    #   You can define other top-level keys that define the message you want
    #   to send to a specific transport protocol (e.g. http).
    #   @return [String]
    #
    # @!attribute [rw] message_attributes
    #   Each message attribute consists of a `Name`, `Type`, and `Value`.
    #   For more information, see [Amazon SNS message attributes][1] in the
    #   Amazon SNS Developer Guide.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-message-attributes.html
    #   @return [Hash<String,Types::MessageAttributeValue>]
    #
    # @!attribute [rw] message_deduplication_id
    #   This parameter applies only to FIFO (first-in-first-out) topics.
    #
    #   The token used for deduplication of messages within a 5-minute
    #   minimum deduplication interval. If a message with a particular
    #   `MessageDeduplicationId` is sent successfully, subsequent messages
    #   with the same `MessageDeduplicationId` are accepted successfully but
    #   aren't delivered.
    #
    #   * Every message must have a unique `MessageDeduplicationId`.
    #
    #     * You may provide a `MessageDeduplicationId` explicitly.
    #
    #     * If you aren't able to provide a `MessageDeduplicationId` and
    #       you enable `ContentBasedDeduplication` for your topic, Amazon
    #       SNS uses a SHA-256 hash to generate the `MessageDeduplicationId`
    #       using the body of the message (but not the attributes of the
    #       message).
    #
    #     * If you don't provide a `MessageDeduplicationId` and the topic
    #       doesn't have `ContentBasedDeduplication` set, the action fails
    #       with an error.
    #
    #     * If the topic has a `ContentBasedDeduplication` set, your
    #       `MessageDeduplicationId` overrides the generated one.
    #
    #   * When `ContentBasedDeduplication` is in effect, messages with
    #     identical content sent within the deduplication interval are
    #     treated as duplicates and only one copy of the message is
    #     delivered.
    #
    #   * If you send one message with `ContentBasedDeduplication` enabled,
    #     and then another message with a `MessageDeduplicationId` that is
    #     the same as the one generated for the first
    #     `MessageDeduplicationId`, the two messages are treated as
    #     duplicates and only one copy of the message is delivered.
    #
    #   <note markdown="1"> The `MessageDeduplicationId` is available to the consumer of the
    #   message (this can be useful for troubleshooting delivery issues).
    #
    #    If a message is sent successfully but the acknowledgement is lost
    #   and the message is resent with the same `MessageDeduplicationId`
    #   after the deduplication interval, Amazon SNS can't detect duplicate
    #   messages.
    #
    #    Amazon SNS continues to keep track of the message deduplication ID
    #   even after the message is received and deleted.
    #
    #    </note>
    #
    #   The length of `MessageDeduplicationId` is 128 characters.
    #
    #   `MessageDeduplicationId` can contain alphanumeric characters `(a-z,
    #   A-Z, 0-9)` and punctuation `` (!"#$%&'()*+,-./:;<=>?@[\]^_`\{|\}~)
    #   ``.
    #   @return [String]
    #
    # @!attribute [rw] message_group_id
    #   This parameter applies only to FIFO (first-in-first-out) topics.
    #
    #   The tag that specifies that a message belongs to a specific message
    #   group. Messages that belong to the same message group are processed
    #   in a FIFO manner (however, messages in different message groups
    #   might be processed out of order). To interleave multiple ordered
    #   streams within a single topic, use `MessageGroupId` values (for
    #   example, session data for multiple users). In this scenario,
    #   multiple consumers can process the topic, but the session data of
    #   each user is processed in a FIFO fashion.
    #
    #   You must associate a non-empty `MessageGroupId` with a message. If
    #   you don't provide a `MessageGroupId`, the action fails.
    #
    #   The length of `MessageGroupId` is 128 characters.
    #
    #   `MessageGroupId` can contain alphanumeric characters `(a-z, A-Z,
    #   0-9)` and punctuation `` (!"#$%&'()*+,-./:;<=>?@[\]^_`\{|\}~) ``.
    #
    #   `MessageGroupId` is required for FIFO topics. You can't use it for
    #   standard topics.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PublishBatchRequestEntry AWS API Documentation
    #
    class PublishBatchRequestEntry < Struct.new(
      :id,
      :message,
      :subject,
      :message_structure,
      :message_attributes,
      :message_deduplication_id,
      :message_group_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] successful
    #   A list of successful `PublishBatch` responses.
    #   @return [Array<Types::PublishBatchResultEntry>]
    #
    # @!attribute [rw] failed
    #   A list of failed `PublishBatch` responses.
    #   @return [Array<Types::BatchResultErrorEntry>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PublishBatchResponse AWS API Documentation
    #
    class PublishBatchResponse < Struct.new(
      :successful,
      :failed)
      SENSITIVE = []
      include Aws::Structure
    end

    # Encloses data related to a successful message in a batch request for
    # topic.
    #
    # @!attribute [rw] id
    #   The `Id` of an entry in a batch request.
    #   @return [String]
    #
    # @!attribute [rw] message_id
    #   An identifier for the message.
    #   @return [String]
    #
    # @!attribute [rw] sequence_number
    #   This parameter applies only to FIFO (first-in-first-out) topics.
    #
    #   The large, non-consecutive number that Amazon SNS assigns to each
    #   message.
    #
    #   The length of `SequenceNumber` is 128 bits. `SequenceNumber`
    #   continues to increase for a particular `MessageGroupId`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PublishBatchResultEntry AWS API Documentation
    #
    class PublishBatchResultEntry < Struct.new(
      :id,
      :message_id,
      :sequence_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for Publish action.
    #
    # @!attribute [rw] topic_arn
    #   The topic you want to publish to.
    #
    #   If you don't specify a value for the `TopicArn` parameter, you must
    #   specify a value for the `PhoneNumber` or `TargetArn` parameters.
    #   @return [String]
    #
    # @!attribute [rw] target_arn
    #   If you don't specify a value for the `TargetArn` parameter, you
    #   must specify a value for the `PhoneNumber` or `TopicArn` parameters.
    #   @return [String]
    #
    # @!attribute [rw] phone_number
    #   The phone number to which you want to deliver an SMS message. Use
    #   E.164 format.
    #
    #   If you don't specify a value for the `PhoneNumber` parameter, you
    #   must specify a value for the `TargetArn` or `TopicArn` parameters.
    #   @return [String]
    #
    # @!attribute [rw] message
    #   The message you want to send.
    #
    #   If you are publishing to a topic and you want to send the same
    #   message to all transport protocols, include the text of the message
    #   as a String value. If you want to send different messages for each
    #   transport protocol, set the value of the `MessageStructure`
    #   parameter to `json` and use a JSON object for the `Message`
    #   parameter.
    #
    #
    #
    #   Constraints:
    #
    #   * With the exception of SMS, messages must be UTF-8 encoded strings
    #     and at most 256 KB in size (262,144 bytes, not 262,144
    #     characters).
    #
    #   * For SMS, each message can contain up to 140 characters. This
    #     character limit depends on the encoding schema. For example, an
    #     SMS message can contain 160 GSM characters, 140 ASCII characters,
    #     or 70 UCS-2 characters.
    #
    #     If you publish a message that exceeds this size limit, Amazon SNS
    #     sends the message as multiple messages, each fitting within the
    #     size limit. Messages aren't truncated mid-word but are cut off at
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
    #   * Outbound notifications are JSON encoded (meaning that the
    #     characters will be reescaped for sending).
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
    #   @return [String]
    #
    # @!attribute [rw] subject
    #   Optional parameter to be used as the "Subject" line when the
    #   message is delivered to email endpoints. This field will also be
    #   included, if present, in the standard JSON messages delivered to
    #   other endpoints.
    #
    #   Constraints: Subjects must be ASCII text that begins with a letter,
    #   number, or punctuation mark; must not include line breaks or control
    #   characters; and must be less than 100 characters long.
    #   @return [String]
    #
    # @!attribute [rw] message_structure
    #   Set `MessageStructure` to `json` if you want to send a different
    #   message for each protocol. For example, using one publish action,
    #   you can send a short message to your SMS subscribers and a longer
    #   message to your email subscribers. If you set `MessageStructure` to
    #   `json`, the value of the `Message` parameter must:
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
    #   @return [String]
    #
    # @!attribute [rw] message_attributes
    #   Message attributes for Publish action.
    #   @return [Hash<String,Types::MessageAttributeValue>]
    #
    # @!attribute [rw] message_deduplication_id
    #   This parameter applies only to FIFO (first-in-first-out) topics. The
    #   `MessageDeduplicationId` can contain up to 128 alphanumeric
    #   characters `(a-z, A-Z, 0-9)` and punctuation ``
    #   (!"#$%&'()*+,-./:;<=>?@[\]^_`\{|\}~) ``.
    #
    #   Every message must have a unique `MessageDeduplicationId`, which is
    #   a token used for deduplication of sent messages. If a message with a
    #   particular `MessageDeduplicationId` is sent successfully, any
    #   message sent with the same `MessageDeduplicationId` during the
    #   5-minute deduplication interval is treated as a duplicate.
    #
    #   If the topic has `ContentBasedDeduplication` set, the system
    #   generates a `MessageDeduplicationId` based on the contents of the
    #   message. Your `MessageDeduplicationId` overrides the generated one.
    #   @return [String]
    #
    # @!attribute [rw] message_group_id
    #   This parameter applies only to FIFO (first-in-first-out) topics. The
    #   `MessageGroupId` can contain up to 128 alphanumeric characters
    #   `(a-z, A-Z, 0-9)` and punctuation ``
    #   (!"#$%&'()*+,-./:;<=>?@[\]^_`\{|\}~) ``.
    #
    #   The `MessageGroupId` is a tag that specifies that a message belongs
    #   to a specific message group. Messages that belong to the same
    #   message group are processed in a FIFO manner (however, messages in
    #   different message groups might be processed out of order). Every
    #   message must include a `MessageGroupId`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PublishInput AWS API Documentation
    #
    class PublishInput < Struct.new(
      :topic_arn,
      :target_arn,
      :phone_number,
      :message,
      :subject,
      :message_structure,
      :message_attributes,
      :message_deduplication_id,
      :message_group_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for Publish action.
    #
    # @!attribute [rw] message_id
    #   Unique identifier assigned to the published message.
    #
    #   Length Constraint: Maximum 100 characters
    #   @return [String]
    #
    # @!attribute [rw] sequence_number
    #   This response element applies only to FIFO (first-in-first-out)
    #   topics.
    #
    #   The sequence number is a large, non-consecutive number that Amazon
    #   SNS assigns to each message. The length of `SequenceNumber` is 128
    #   bits. `SequenceNumber` continues to increase for each
    #   `MessageGroupId`.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PublishResponse AWS API Documentation
    #
    class PublishResponse < Struct.new(
      :message_id,
      :sequence_number)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] resource_arn
    #   The ARN of the topic whose `DataProtectionPolicy` you want to add or
    #   update.
    #
    #   For more information about ARNs, see [Amazon Resource Names
    #   (ARNs)][1] in the Amazon Web Services General Reference.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   @return [String]
    #
    # @!attribute [rw] data_protection_policy
    #   The JSON serialization of the topic's `DataProtectionPolicy`.
    #
    #   The `DataProtectionPolicy` must be in JSON string format.
    #
    #   Length Constraints: Maximum length of 30,720.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/PutDataProtectionPolicyInput AWS API Documentation
    #
    class PutDataProtectionPolicyInput < Struct.new(
      :resource_arn,
      :data_protection_policy)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for RemovePermission action.
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the topic whose access control policy you wish to modify.
    #   @return [String]
    #
    # @!attribute [rw] label
    #   The unique label of the statement you want to remove.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/RemovePermissionInput AWS API Documentation
    #
    class RemovePermissionInput < Struct.new(
      :topic_arn,
      :label)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the request parameter has exceeded the maximum number
    # of concurrent message replays.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ReplayLimitExceededException AWS API Documentation
    #
    class ReplayLimitExceededException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Can’t perform the action on the specified resource. Make sure that the
    # resource exists.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ResourceNotFoundException AWS API Documentation
    #
    class ResourceNotFoundException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # A verified or pending destination phone number in the SMS sandbox.
    #
    # When you start using Amazon SNS to send SMS messages, your Amazon Web
    # Services account is in the *SMS sandbox*. The SMS sandbox provides a
    # safe environment for you to try Amazon SNS features without risking
    # your reputation as an SMS sender. While your Amazon Web Services
    # account is in the SMS sandbox, you can use all of the features of
    # Amazon SNS. However, you can send SMS messages only to verified
    # destination phone numbers. For more information, including how to move
    # out of the sandbox to send messages without restrictions, see [SMS
    # sandbox][1] in the *Amazon SNS Developer Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-sms-sandbox.html
    #
    # @!attribute [rw] phone_number
    #   The destination phone number.
    #   @return [String]
    #
    # @!attribute [rw] status
    #   The destination phone number's verification status.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SMSSandboxPhoneNumber AWS API Documentation
    #
    class SMSSandboxPhoneNumber < Struct.new(
      :phone_number,
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for SetEndpointAttributes action.
    #
    # @!attribute [rw] endpoint_arn
    #   EndpointArn used for SetEndpointAttributes action.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   A map of the endpoint attributes. Attributes in this map include the
    #   following:
    #
    #   * `CustomUserData` – arbitrary user data to associate with the
    #     endpoint. Amazon SNS does not use this data. The data must be in
    #     UTF-8 format and less than 2KB.
    #
    #   * `Enabled` – flag that enables/disables delivery to the endpoint.
    #     Amazon SNS will set this to false when a notification service
    #     indicates to Amazon SNS that the endpoint is invalid. Users can
    #     set it back to true, typically after updating Token.
    #
    #   * `Token` – device token, also referred to as a registration id, for
    #     an app and mobile device. This is returned from the notification
    #     service when an app and mobile device are registered with the
    #     notification service.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetEndpointAttributesInput AWS API Documentation
    #
    class SetEndpointAttributesInput < Struct.new(
      :endpoint_arn,
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for SetPlatformApplicationAttributes action.
    #
    # @!attribute [rw] platform_application_arn
    #   PlatformApplicationArn for SetPlatformApplicationAttributes action.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   A map of the platform application attributes. Attributes in this map
    #   include the following:
    #
    #   * `PlatformCredential` – The credential received from the
    #     notification service.
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
    #     * For Apple Services using token credentials, `PlatformPrincipal`
    #       is signing key ID.
    #
    #     * For GCM (Firebase Cloud Messaging), there is no
    #       `PlatformPrincipal`.
    #   ^
    #
    #   * `EventEndpointCreated` – Topic ARN to which `EndpointCreated`
    #     event notifications are sent.
    #
    #   * `EventEndpointDeleted` – Topic ARN to which `EndpointDeleted`
    #     event notifications are sent.
    #
    #   * `EventEndpointUpdated` – Topic ARN to which `EndpointUpdate` event
    #     notifications are sent.
    #
    #   * `EventDeliveryFailure` – Topic ARN to which `DeliveryFailure`
    #     event notifications are sent upon Direct Publish delivery failure
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
    #   * `ApplePlatformBundleID` – The bundle identifier that's assigned
    #     to your iOS app.
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetPlatformApplicationAttributesInput AWS API Documentation
    #
    class SetPlatformApplicationAttributesInput < Struct.new(
      :platform_application_arn,
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # The input for the SetSMSAttributes action.
    #
    # @!attribute [rw] attributes
    #   The default settings for sending SMS messages from your Amazon Web
    #   Services account. You can set values for the following attribute
    #   names:
    #
    #   `MonthlySpendLimit` – The maximum amount in USD that you are willing
    #   to spend each month to send SMS messages. When Amazon SNS determines
    #   that sending an SMS message would incur a cost that exceeds this
    #   limit, it stops sending SMS messages within minutes.
    #
    #   Amazon SNS stops sending SMS messages within minutes of the limit
    #   being crossed. During that interval, if you continue to send SMS
    #   messages, you will incur costs that exceed your limit.
    #
    #   By default, the spend limit is set to the maximum allowed by Amazon
    #   SNS. If you want to raise the limit, submit an [SNS Limit Increase
    #   case][1]. For **New limit value**, enter your desired monthly spend
    #   limit. In the **Use Case Description** field, explain that you are
    #   requesting an SMS monthly spend limit increase.
    #
    #   `DeliveryStatusIAMRole` – The ARN of the IAM role that allows Amazon
    #   SNS to write logs about SMS deliveries in CloudWatch Logs. For each
    #   SMS message that you send, Amazon SNS writes a log that includes the
    #   message price, the success or failure status, the reason for failure
    #   (if the message failed), the message dwell time, and other
    #   information.
    #
    #   `DeliveryStatusSuccessSamplingRate` – The percentage of successful
    #   SMS deliveries for which Amazon SNS will write logs in CloudWatch
    #   Logs. The value can be an integer from 0 - 100. For example, to
    #   write logs only for failed deliveries, set this value to `0`. To
    #   write logs for 10% of your successful deliveries, set it to `10`.
    #
    #   `DefaultSenderID` – A string, such as your business brand, that is
    #   displayed as the sender on the receiving device. Support for sender
    #   IDs varies by country. The sender ID can be 1 - 11 alphanumeric
    #   characters, and it must contain at least one letter.
    #
    #   `DefaultSMSType` – The type of SMS message that you will send by
    #   default. You can assign the following values:
    #
    #   * `Promotional` – (Default) Noncritical messages, such as marketing
    #     messages. Amazon SNS optimizes the message delivery to incur the
    #     lowest cost.
    #
    #   * `Transactional` – Critical messages that support customer
    #     transactions, such as one-time passcodes for multi-factor
    #     authentication. Amazon SNS optimizes the message delivery to
    #     achieve the highest reliability.
    #
    #   `UsageReportS3Bucket` – The name of the Amazon S3 bucket to receive
    #   daily SMS usage reports from Amazon SNS. Each day, Amazon SNS will
    #   deliver a usage report as a CSV file to the bucket. The report
    #   includes the following information for each SMS message that was
    #   successfully delivered by your Amazon Web Services account:
    #
    #   * Time that the message was published (in UTC)
    #
    #   * Message ID
    #
    #   * Destination phone number
    #
    #   * Message type
    #
    #   * Delivery status
    #
    #   * Message price (in USD)
    #
    #   * Part number (a message is split into multiple parts if it is too
    #     long for a single message)
    #
    #   * Total number of parts
    #
    #   To receive the report, the bucket must have a policy that allows the
    #   Amazon SNS service principal to perform the `s3:PutObject` and
    #   `s3:GetBucketLocation` actions.
    #
    #   For an example bucket policy and usage report, see [Monitoring SMS
    #   Activity][2] in the *Amazon SNS Developer Guide*.
    #
    #
    #
    #   [1]: https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&amp;limitType=service-code-sns
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sms_stats.html
    #   @return [Hash<String,String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetSMSAttributesInput AWS API Documentation
    #
    class SetSMSAttributesInput < Struct.new(
      :attributes)
      SENSITIVE = []
      include Aws::Structure
    end

    # The response for the SetSMSAttributes action.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetSMSAttributesResponse AWS API Documentation
    #
    class SetSMSAttributesResponse < Aws::EmptyStructure; end

    # Input for SetSubscriptionAttributes action.
    #
    # @!attribute [rw] subscription_arn
    #   The ARN of the subscription to modify.
    #   @return [String]
    #
    # @!attribute [rw] attribute_name
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the
    #   special request parameters that this action uses:
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
    #     delivery to Amazon SQS or HTTP/S endpoints. This eliminates the
    #     need for the endpoints to process JSON formatting, which is
    #     otherwise created for Amazon SNS metadata.
    #
    #   * `RedrivePolicy` – When specified, sends undeliverable messages to
    #     the specified Amazon SQS dead-letter queue. Messages that can't
    #     be delivered due to client errors (for example, when the
    #     subscribed endpoint is unreachable) or server errors (for example,
    #     when the service that powers the subscribed endpoint becomes
    #     unavailable) are held in the dead-letter queue for further
    #     analysis or reprocessing.
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
    #   @return [String]
    #
    # @!attribute [rw] attribute_value
    #   The new value for the attribute in JSON format.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetSubscriptionAttributesInput AWS API Documentation
    #
    class SetSubscriptionAttributesInput < Struct.new(
      :subscription_arn,
      :attribute_name,
      :attribute_value)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for SetTopicAttributes action.
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the topic to modify.
    #   @return [String]
    #
    # @!attribute [rw] attribute_name
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the
    #   special request parameters that the `SetTopicAttributes` action
    #   uses:
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
    #     default, only the topic owner can publish or subscribe to the
    #     topic.
    #
    #   * `TracingConfig` – Tracing mode of an Amazon SNS topic. By default
    #     `TracingConfig` is set to `PassThrough`, and the topic passes
    #     through the tracing header it receives from an Amazon SNS
    #     publisher to its subscriptions. If set to `Active`, Amazon SNS
    #     will vend X-Ray segment data to topic owner account if the sampled
    #     flag in the tracing header is true. This is only supported on
    #     standard topics.
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
    #     * `LambdaFailureFeedbackRoleArn` – Indicates failed message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Lambda endpoint.
    #
    #   * Platform application endpoint
    #
    #     * `ApplicationSuccessFeedbackRoleArn` – Indicates successful
    #       message delivery status for an Amazon SNS topic that is
    #       subscribed to an Amazon Web Services application endpoint.
    #
    #     * `ApplicationSuccessFeedbackSampleRate` – Indicates percentage of
    #       successful messages to sample for an Amazon SNS topic that is
    #       subscribed to an Amazon Web Services application endpoint.
    #
    #     * `ApplicationFailureFeedbackRoleArn` – Indicates failed message
    #       delivery status for an Amazon SNS topic that is subscribed to an
    #       Amazon Web Services application endpoint.
    #
    #     <note markdown="1"> In addition to being able to configure topic attributes for
    #     message delivery status of notification messages sent to Amazon
    #     SNS application endpoints, you can also configure application
    #     attributes for the delivery status of push notification messages
    #     sent to push notification services.
    #
    #      For example, For more information, see [Using Amazon SNS
    #     Application Attributes for Message Delivery Status][1].
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
    #       status for an Amazon SNS topic that is subscribed to an Amazon
    #       SQS endpoint.
    #
    #   <note markdown="1"> The &lt;ENDPOINT&gt;SuccessFeedbackRoleArn and
    #   &lt;ENDPOINT&gt;FailureFeedbackRoleArn attributes are used to give
    #   Amazon SNS write access to use CloudWatch Logs on your behalf. The
    #   &lt;ENDPOINT&gt;SuccessFeedbackSampleRate attribute is for
    #   specifying the sample rate percentage (0-100) of successfully
    #   delivered messages. After you configure the
    #   &lt;ENDPOINT&gt;FailureFeedbackRoleArn attribute, then all failed
    #   message deliveries generate CloudWatch Logs.
    #
    #    </note>
    #
    #   The following attribute applies only to [server-side-encryption][2]:
    #
    #   * `KmsMasterKeyId` – The ID of an Amazon Web Services managed
    #     customer master key (CMK) for Amazon SNS or a custom CMK. For more
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
    #     * By default, `ContentBasedDeduplication` is set to `false`. If
    #       you create a FIFO topic and this attribute is `false`, you must
    #       specify a value for the `MessageDeduplicationId` parameter for
    #       the [Publish][6] action.
    #
    #     * When you set `ContentBasedDeduplication` to `true`, Amazon SNS
    #       uses a SHA-256 hash to generate the `MessageDeduplicationId`
    #       using the body of the message (but not the attributes of the
    #       message).
    #
    #       (Optional) To override the generated value, you can specify a
    #       value for the `MessageDeduplicationId` parameter for the
    #       `Publish` action.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/sns/latest/dg/sns-msg-status.html
    #   [2]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html
    #   [3]: https://docs.aws.amazon.com/sns/latest/dg/sns-server-side-encryption.html#sse-key-terms
    #   [4]: https://docs.aws.amazon.com/kms/latest/APIReference/API_DescribeKey.html#API_DescribeKey_RequestParameters
    #   [5]: https://docs.aws.amazon.com/sns/latest/dg/sns-fifo-topics.html
    #   [6]: https://docs.aws.amazon.com/sns/latest/api/API_Publish.html
    #   @return [String]
    #
    # @!attribute [rw] attribute_value
    #   The new value for the attribute.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SetTopicAttributesInput AWS API Documentation
    #
    class SetTopicAttributesInput < Struct.new(
      :topic_arn,
      :attribute_name,
      :attribute_value)
      SENSITIVE = []
      include Aws::Structure
    end

    # A tag has been added to a resource with the same ARN as a deleted
    # resource. Wait a short while and then retry the operation.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/StaleTagException AWS API Documentation
    #
    class StaleTagException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for Subscribe action.
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the topic you want to subscribe to.
    #   @return [String]
    #
    # @!attribute [rw] protocol
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
    #   @return [String]
    #
    # @!attribute [rw] endpoint
    #   The endpoint that you want to receive notifications. Endpoints vary
    #   by protocol:
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
    #   * For the `application` protocol, the endpoint is the EndpointArn of
    #     a mobile app and device.
    #
    #   * For the `lambda` protocol, the endpoint is the ARN of an Lambda
    #     function.
    #
    #   * For the `firehose` protocol, the endpoint is the ARN of an Amazon
    #     Kinesis Data Firehose delivery stream.
    #   @return [String]
    #
    # @!attribute [rw] attributes
    #   A map of attributes with their corresponding values.
    #
    #   The following lists the names, descriptions, and values of the
    #   special request parameters that the `Subscribe` action uses:
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
    #     delivery to Amazon SQS or HTTP/S endpoints. This eliminates the
    #     need for the endpoints to process JSON formatting, which is
    #     otherwise created for Amazon SNS metadata.
    #
    #   * `RedrivePolicy` – When specified, sends undeliverable messages to
    #     the specified Amazon SQS dead-letter queue. Messages that can't
    #     be delivered due to client errors (for example, when the
    #     subscribed endpoint is unreachable) or server errors (for example,
    #     when the service that powers the subscribed endpoint becomes
    #     unavailable) are held in the dead-letter queue for further
    #     analysis or reprocessing.
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
    #   @return [Hash<String,String>]
    #
    # @!attribute [rw] return_subscription_arn
    #   Sets whether the response from the `Subscribe` request includes the
    #   subscription ARN, even if the subscription is not yet confirmed.
    #
    #   If you set this parameter to `true`, the response includes the ARN
    #   in all cases, even if the subscription is not yet confirmed. In
    #   addition to the ARN for confirmed subscriptions, the response also
    #   includes the `pending subscription` ARN value for subscriptions that
    #   aren't yet confirmed. A subscription becomes confirmed when the
    #   subscriber calls the `ConfirmSubscription` action with a
    #   confirmation token.
    #
    #
    #
    #   The default value is `false`.
    #   @return [Boolean]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SubscribeInput AWS API Documentation
    #
    class SubscribeInput < Struct.new(
      :topic_arn,
      :protocol,
      :endpoint,
      :attributes,
      :return_subscription_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Response for Subscribe action.
    #
    # @!attribute [rw] subscription_arn
    #   The ARN of the subscription if it is confirmed, or the string
    #   "pending confirmation" if the subscription requires confirmation.
    #   However, if the API request parameter `ReturnSubscriptionArn` is
    #   true, then the value is always the subscription ARN, even if the
    #   subscription requires confirmation.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SubscribeResponse AWS API Documentation
    #
    class SubscribeResponse < Struct.new(
      :subscription_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # A wrapper type for the attributes of an Amazon SNS subscription.
    #
    # @!attribute [rw] subscription_arn
    #   The subscription's ARN.
    #   @return [String]
    #
    # @!attribute [rw] owner
    #   The subscription's owner.
    #   @return [String]
    #
    # @!attribute [rw] protocol
    #   The subscription's protocol.
    #   @return [String]
    #
    # @!attribute [rw] endpoint
    #   The subscription's endpoint (format depends on the protocol).
    #   @return [String]
    #
    # @!attribute [rw] topic_arn
    #   The ARN of the subscription's topic.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Subscription AWS API Documentation
    #
    class Subscription < Struct.new(
      :subscription_arn,
      :owner,
      :protocol,
      :endpoint,
      :topic_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the customer already owns the maximum allowed number of
    # subscriptions.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/SubscriptionLimitExceededException AWS API Documentation
    #
    class SubscriptionLimitExceededException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The list of tags to be added to the specified topic.
    #
    # @!attribute [rw] key
    #   The required key portion of the tag.
    #   @return [String]
    #
    # @!attribute [rw] value
    #   The optional value portion of the tag.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Tag AWS API Documentation
    #
    class Tag < Struct.new(
      :key,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

    # Can't add more than 50 tags to a topic.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TagLimitExceededException AWS API Documentation
    #
    class TagLimitExceededException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request doesn't comply with the IAM tag policy. Correct your
    # request and then retry it.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TagPolicyException AWS API Documentation
    #
    class TagPolicyException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] resource_arn
    #   The ARN of the topic to which to add tags.
    #   @return [String]
    #
    # @!attribute [rw] tags
    #   The tags to be added to the specified topic. A tag consists of a
    #   required key and an optional value.
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TagResourceRequest AWS API Documentation
    #
    class TagResourceRequest < Struct.new(
      :resource_arn,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TagResourceResponse AWS API Documentation
    #
    class TagResourceResponse < Aws::EmptyStructure; end

    # Indicates that the rate at which requests have been submitted for this
    # action exceeds the limit for your Amazon Web Services account.
    #
    # @!attribute [rw] message
    #   Throttled request.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ThrottledException AWS API Documentation
    #
    class ThrottledException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The batch request contains more entries than permissible.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TooManyEntriesInBatchRequestException AWS API Documentation
    #
    class TooManyEntriesInBatchRequestException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # A wrapper type for the topic's Amazon Resource Name (ARN). To
    # retrieve a topic's attributes, use `GetTopicAttributes`.
    #
    # @!attribute [rw] topic_arn
    #   The topic's ARN.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/Topic AWS API Documentation
    #
    class Topic < Struct.new(
      :topic_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the customer already owns the maximum allowed number of
    # topics.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/TopicLimitExceededException AWS API Documentation
    #
    class TopicLimitExceededException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Input for Unsubscribe action.
    #
    # @!attribute [rw] subscription_arn
    #   The ARN of the subscription to be deleted.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/UnsubscribeInput AWS API Documentation
    #
    class UnsubscribeInput < Struct.new(
      :subscription_arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] resource_arn
    #   The ARN of the topic from which to remove tags.
    #   @return [String]
    #
    # @!attribute [rw] tag_keys
    #   The list of tag keys to remove from the specified topic.
    #   @return [Array<String>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/UntagResourceRequest AWS API Documentation
    #
    class UntagResourceRequest < Struct.new(
      :resource_arn,
      :tag_keys)
      SENSITIVE = []
      include Aws::Structure
    end

    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/UntagResourceResponse AWS API Documentation
    #
    class UntagResourceResponse < Aws::EmptyStructure; end

    # Indicates that a request parameter does not comply with the associated
    # constraints.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/UserErrorException AWS API Documentation
    #
    class UserErrorException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that a parameter in the request is invalid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/ValidationException AWS API Documentation
    #
    class ValidationException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Indicates that the one-time password (OTP) used for verification is
    # invalid.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @!attribute [rw] status
    #   The status of the verification error.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/VerificationException AWS API Documentation
    #
    class VerificationException < Struct.new(
      :message,
      :status)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] phone_number
    #   The destination phone number to verify.
    #   @return [String]
    #
    # @!attribute [rw] one_time_password
    #   The OTP sent to the destination number from the
    #   `CreateSMSSandBoxPhoneNumber` call.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/VerifySMSSandboxPhoneNumberInput AWS API Documentation
    #
    class VerifySMSSandboxPhoneNumberInput < Struct.new(
      :phone_number,
      :one_time_password)
      SENSITIVE = []
      include Aws::Structure
    end

    # The destination phone number's verification status.
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sns-2010-03-31/VerifySMSSandboxPhoneNumberResult AWS API Documentation
    #
    class VerifySMSSandboxPhoneNumberResult < Aws::EmptyStructure; end

  end
end
