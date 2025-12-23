# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  module Types

    # @!attribute [rw] role_arn
    #   The Amazon Resource Name (ARN) of the role to assume.
    #   @return [String]
    #
    # @!attribute [rw] role_session_name
    #   An identifier for the assumed role session.
    #
    #   Use the role session name to uniquely identify a session when the
    #   same role is assumed by different principals or for different
    #   reasons. In cross-account scenarios, the role session name is
    #   visible to, and can be logged by the account that owns the role. The
    #   role session name is also used in the ARN of the assumed role
    #   principal. This means that subsequent cross-account API requests
    #   that use the temporary security credentials will expose the role
    #   session name to the external account in their CloudTrail logs.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as managed session policies. The policies must exist
    #   in the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plaintext that you use for both inline and
    #   managed session policies can't exceed 2,048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and Amazon
    #   Web Services Service Namespaces][1] in the Amazon Web Services
    #   General Reference.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary
    #   credentials. The resulting session's permissions are the
    #   intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in
    #   subsequent Amazon Web Services API calls to access resources in the
    #   account that owns the role. You cannot use session policies to grant
    #   more permissions than those allowed by the identity-based policy of
    #   the role that is being assumed. For more information, see [Session
    #   Policies][2] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   This parameter is optional. Passing policies to this operation
    #   returns new temporary credentials. The resulting session's
    #   permissions are the intersection of the role's identity-based
    #   policy and the session policies. You can use the role's temporary
    #   credentials in subsequent Amazon Web Services API calls to access
    #   resources in the account that owns the role. You cannot use session
    #   policies to grant more permissions than those allowed by the
    #   identity-based policy of the role that is being assumed. For more
    #   information, see [Session Policies][1] in the *IAM User Guide*.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of
    #   the valid character list (\\u0020 through \\u00FF). It can also
    #   include the tab (\\u0009), linefeed (\\u000A), and carriage return
    #   (\\u000D) characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, of the role session. The value specified
    #   can range from 900 seconds (15 minutes) up to the maximum session
    #   duration set for the role. The maximum session duration setting can
    #   have a value from 1 hour to 12 hours. If you specify a value higher
    #   than this setting or the administrator setting (whichever is lower),
    #   the operation fails. For example, if you specify a session duration
    #   of 12 hours, but your administrator set the maximum session duration
    #   to 6 hours, your operation fails.
    #
    #   Role chaining limits your Amazon Web Services CLI or Amazon Web
    #   Services API role session to a maximum of one hour. When you use the
    #   `AssumeRole` API operation to assume a role, you can specify the
    #   duration of your role session with the `DurationSeconds` parameter.
    #   You can specify a parameter value of up to 43200 seconds (12 hours),
    #   depending on the maximum session duration setting for your role.
    #   However, if you assume a role using role chaining and provide a
    #   `DurationSeconds` parameter value greater than one hour, the
    #   operation fails. To learn how to view the maximum value for your
    #   role, see [View the Maximum Session Duration Setting for a Role][1]
    #   in the *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned
    #   credentials. The request to the federation endpoint for a console
    #   sign-in token takes a `SessionDuration` parameter that specifies the
    #   maximum length of the console session. For more information, see
    #   [Creating a URL that Enables Federated Users to Access the Amazon
    #   Web Services Management Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #   @return [Integer]
    #
    # @!attribute [rw] tags
    #   A list of session tags that you want to pass. Each session tag
    #   consists of a key name and an associated value. For more information
    #   about session tags, see [Tagging Amazon Web Services STS
    #   Sessions][1] in the *IAM User Guide*.
    #
    #   This parameter is optional. You can pass up to 50 session tags. The
    #   plaintext session tag keys can’t exceed 128 characters, and the
    #   values can’t exceed 256 characters. For these and additional limits,
    #   see [IAM and STS Character Limits][2] in the *IAM User Guide*.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #   You can pass a session tag with the same key as a tag that is
    #   already attached to the role. When you do, session tags override a
    #   role tag with the same key.
    #
    #   Tag key–value pairs are not case sensitive, but case is preserved.
    #   This means that you cannot have separate `Department` and
    #   `department` tag keys. Assume that the role has the
    #   `Department`=`Marketing` tag and you pass the
    #   `department`=`engineering` session tag. `Department` and
    #   `department` are not saved as separate tags, and the session tag
    #   passed in the request takes precedence over the role tag.
    #
    #   Additionally, if you used temporary credentials to perform this
    #   operation, the new session inherits any transitive session tags from
    #   the calling session. If you pass a session tag with the same key as
    #   an inherited tag, the operation fails. To view the inherited tags
    #   for a session, see the CloudTrail logs. For more information, see
    #   [Viewing Session Tags in CloudTrail][3] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    #   [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_ctlogs
    #   @return [Array<Types::Tag>]
    #
    # @!attribute [rw] transitive_tag_keys
    #   A list of keys for session tags that you want to set as transitive.
    #   If you set a tag key as transitive, the corresponding key and value
    #   passes to subsequent sessions in a role chain. For more information,
    #   see [Chaining Roles with Session Tags][1] in the *IAM User Guide*.
    #
    #   This parameter is optional. When you set session tags as transitive,
    #   the session policy and session tags packed binary limit is not
    #   affected.
    #
    #   If you choose not to specify a transitive tag key, then no tags are
    #   passed from this session to any subsequent sessions.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html#id_session-tags_role-chaining
    #   @return [Array<String>]
    #
    # @!attribute [rw] external_id
    #   A unique identifier that might be required when you assume a role in
    #   another account. If the administrator of the account to which the
    #   role belongs provided you with an external ID, then provide that
    #   value in the `ExternalId` parameter. This value can be any string,
    #   such as a passphrase or account number. A cross-account role is
    #   usually set up to trust everyone in an account. Therefore, the
    #   administrator of the trusting account might send an external ID to
    #   the administrator of the trusted account. That way, only someone
    #   with the ID can assume the role, rather than everyone in the
    #   account. For more information about the external ID, see [How to Use
    #   an External ID When Granting Access to Your Amazon Web Services
    #   Resources to a Third Party][1] in the *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user_externalid.html
    #   @return [String]
    #
    # @!attribute [rw] serial_number
    #   The identification number of the MFA device that is associated with
    #   the user who is making the `AssumeRole` call. Specify this value if
    #   the trust policy of the role being assumed includes a condition that
    #   requires MFA authentication. The value is either the serial number
    #   for a hardware device (such as `GAHT12345678`) or an Amazon Resource
    #   Name (ARN) for a virtual device (such as
    #   `arn:aws:iam::123456789012:mfa/user`).
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] token_code
    #   The value provided by the MFA device, if the trust policy of the
    #   role being assumed requires MFA. (In other words, if the policy
    #   includes a condition that tests for MFA). If the role being assumed
    #   requires MFA and if the `TokenCode` value is missing or expired, the
    #   `AssumeRole` call returns an "access denied" error.
    #
    #   The format for this parameter, as described by its regex pattern, is
    #   a sequence of six numeric digits.
    #   @return [String]
    #
    # @!attribute [rw] source_identity
    #   The source identity specified by the principal that is calling the
    #   `AssumeRole` operation.
    #
    #   You can require users to specify a source identity when they assume
    #   a role. You do this by using the `sts:SourceIdentity` condition key
    #   in a role trust policy. You can use source identity information in
    #   CloudTrail logs to determine who took actions with a role. You can
    #   use the `aws:SourceIdentity` condition key to further control access
    #   to Amazon Web Services resources based on the value of source
    #   identity. For more information about using source identity, see
    #   [Monitor and control actions taken with assumed roles][1] in the
    #   *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-. You cannot use a value that begins with the text
    #   `aws:`. This prefix is reserved for Amazon Web Services internal
    #   use.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_monitor.html
    #   @return [String]
    #
    # @!attribute [rw] provided_contexts
    #   A list of previously acquired trusted context assertions in the
    #   format of a JSON array. The trusted context assertion is signed and
    #   encrypted by Amazon Web Services STS.
    #
    #   The following is an example of a `ProvidedContext` value that
    #   includes a single trusted context assertion and the ARN of the
    #   context provider from which the trusted context assertion was
    #   generated.
    #
    #   `[\{"ProviderArn":"arn:aws:iam::aws:contextProvider/identitycenter","ContextAssertion":"trusted-context-assertion"\}]`
    #   @return [Array<Types::ProvidedContext>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleRequest AWS API Documentation
    #
    class AssumeRoleRequest < Struct.new(
      :role_arn,
      :role_session_name,
      :policy_arns,
      :policy,
      :duration_seconds,
      :tags,
      :transitive_tag_keys,
      :external_id,
      :serial_number,
      :token_code,
      :source_identity,
      :provided_contexts)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the response to a successful AssumeRole request, including
    # temporary Amazon Web Services credentials that can be used to make
    # Amazon Web Services requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] assumed_role_user
    #   The Amazon Resource Name (ARN) and the assumed role ID, which are
    #   identifiers that you can use to refer to the resulting temporary
    #   security credentials. For example, you can reference these
    #   credentials as a principal in a resource-based policy by using the
    #   ARN or assumed role ID. The ARN and ID include the `RoleSessionName`
    #   that you specified when you called `AssumeRole`.
    #   @return [Types::AssumedRoleUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the packed size of the session
    #   policies and session tags combined passed in the request. The
    #   request fails if the packed size is greater than 100 percent, which
    #   means the policies and tags exceeded the allowed space.
    #   @return [Integer]
    #
    # @!attribute [rw] source_identity
    #   The source identity specified by the principal that is calling the
    #   `AssumeRole` operation.
    #
    #   You can require users to specify a source identity when they assume
    #   a role. You do this by using the `sts:SourceIdentity` condition key
    #   in a role trust policy. You can use source identity information in
    #   CloudTrail logs to determine who took actions with a role. You can
    #   use the `aws:SourceIdentity` condition key to further control access
    #   to Amazon Web Services resources based on the value of source
    #   identity. For more information about using source identity, see
    #   [Monitor and control actions taken with assumed roles][1] in the
    #   *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_monitor.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleResponse AWS API Documentation
    #
    class AssumeRoleResponse < Struct.new(
      :credentials,
      :assumed_role_user,
      :packed_policy_size,
      :source_identity)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #   @return [String]
    #
    # @!attribute [rw] principal_arn
    #   The Amazon Resource Name (ARN) of the SAML provider in IAM that
    #   describes the IdP.
    #   @return [String]
    #
    # @!attribute [rw] saml_assertion
    #   The base64 encoded SAML authentication response provided by the IdP.
    #
    #   For more information, see [Configuring a Relying Party and Adding
    #   Claims][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/create-role-saml-IdP-tasks.html
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as managed session policies. The policies must exist
    #   in the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plaintext that you use for both inline and
    #   managed session policies can't exceed 2,048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and Amazon
    #   Web Services Service Namespaces][1] in the Amazon Web Services
    #   General Reference.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary
    #   credentials. The resulting session's permissions are the
    #   intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in
    #   subsequent Amazon Web Services API calls to access resources in the
    #   account that owns the role. You cannot use session policies to grant
    #   more permissions than those allowed by the identity-based policy of
    #   the role that is being assumed. For more information, see [Session
    #   Policies][2] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   This parameter is optional. Passing policies to this operation
    #   returns new temporary credentials. The resulting session's
    #   permissions are the intersection of the role's identity-based
    #   policy and the session policies. You can use the role's temporary
    #   credentials in subsequent Amazon Web Services API calls to access
    #   resources in the account that owns the role. You cannot use session
    #   policies to grant more permissions than those allowed by the
    #   identity-based policy of the role that is being assumed. For more
    #   information, see [Session Policies][1] in the *IAM User Guide*.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of
    #   the valid character list (\\u0020 through \\u00FF). It can also
    #   include the tab (\\u0009), linefeed (\\u000A), and carriage return
    #   (\\u000D) characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, of the role session. Your role session
    #   lasts for the duration that you specify for the `DurationSeconds`
    #   parameter, or until the time specified in the SAML authentication
    #   response's `SessionNotOnOrAfter` value, whichever is shorter. You
    #   can provide a `DurationSeconds` value from 900 seconds (15 minutes)
    #   up to the maximum session duration setting for the role. This
    #   setting can have a value from 1 hour to 12 hours. If you specify a
    #   value higher than this setting, the operation fails. For example, if
    #   you specify a session duration of 12 hours, but your administrator
    #   set the maximum session duration to 6 hours, your operation fails.
    #   To learn how to view the maximum value for your role, see [View the
    #   Maximum Session Duration Setting for a Role][1] in the *IAM User
    #   Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned
    #   credentials. The request to the federation endpoint for a console
    #   sign-in token takes a `SessionDuration` parameter that specifies the
    #   maximum length of the console session. For more information, see
    #   [Creating a URL that Enables Federated Users to Access the Amazon
    #   Web Services Management Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithSAMLRequest AWS API Documentation
    #
    class AssumeRoleWithSAMLRequest < Struct.new(
      :role_arn,
      :principal_arn,
      :saml_assertion,
      :policy_arns,
      :policy,
      :duration_seconds)
      SENSITIVE = [:saml_assertion]
      include Aws::Structure
    end

    # Contains the response to a successful AssumeRoleWithSAML request,
    # including temporary Amazon Web Services credentials that can be used
    # to make Amazon Web Services requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] assumed_role_user
    #   The identifiers for the temporary security credentials that the
    #   operation returns.
    #   @return [Types::AssumedRoleUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the packed size of the session
    #   policies and session tags combined passed in the request. The
    #   request fails if the packed size is greater than 100 percent, which
    #   means the policies and tags exceeded the allowed space.
    #   @return [Integer]
    #
    # @!attribute [rw] subject
    #   The value of the `NameID` element in the `Subject` element of the
    #   SAML assertion.
    #   @return [String]
    #
    # @!attribute [rw] subject_type
    #   The format of the name ID, as defined by the `Format` attribute in
    #   the `NameID` element of the SAML assertion. Typical examples of the
    #   format are `transient` or `persistent`.
    #
    #   If the format includes the prefix
    #   `urn:oasis:names:tc:SAML:2.0:nameid-format`, that prefix is removed.
    #   For example, `urn:oasis:names:tc:SAML:2.0:nameid-format:transient`
    #   is returned as `transient`. If the format includes any other prefix,
    #   the format is returned with no modifications.
    #   @return [String]
    #
    # @!attribute [rw] issuer
    #   The value of the `Issuer` element of the SAML assertion.
    #   @return [String]
    #
    # @!attribute [rw] audience
    #   The value of the `Recipient` attribute of the
    #   `SubjectConfirmationData` element of the SAML assertion.
    #   @return [String]
    #
    # @!attribute [rw] name_qualifier
    #   A hash value based on the concatenation of the following:
    #
    #   * The `Issuer` response value.
    #
    #   * The Amazon Web Services account ID.
    #
    #   * The friendly name (the last part of the ARN) of the SAML provider
    #     in IAM.
    #
    #   The combination of `NameQualifier` and `Subject` can be used to
    #   uniquely identify a user.
    #
    #   The following pseudocode shows how the hash value is calculated:
    #
    #   `BASE64 ( SHA1 ( "https://example.com/saml" + "123456789012" +
    #   "/MySAMLIdP" ) )`
    #   @return [String]
    #
    # @!attribute [rw] source_identity
    #   The value in the `SourceIdentity` attribute in the SAML assertion.
    #
    #   You can require users to set a source identity value when they
    #   assume a role. You do this by using the `sts:SourceIdentity`
    #   condition key in a role trust policy. That way, actions that are
    #   taken with the role are associated with that user. After the source
    #   identity is set, the value cannot be changed. It is present in the
    #   request for all actions that are taken by the role and persists
    #   across [chained role][1] sessions. You can configure your SAML
    #   identity provider to use an attribute associated with your users,
    #   like user name or email, as the source identity when calling
    #   `AssumeRoleWithSAML`. You do this by adding an attribute to the SAML
    #   assertion. For more information about using source identity, see
    #   [Monitor and control actions taken with assumed roles][2] in the
    #   *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts#iam-term-role-chaining
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_monitor.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithSAMLResponse AWS API Documentation
    #
    class AssumeRoleWithSAMLResponse < Struct.new(
      :credentials,
      :assumed_role_user,
      :packed_policy_size,
      :subject,
      :subject_type,
      :issuer,
      :audience,
      :name_qualifier,
      :source_identity)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] role_arn
    #   The Amazon Resource Name (ARN) of the role that the caller is
    #   assuming.
    #   @return [String]
    #
    # @!attribute [rw] role_session_name
    #   An identifier for the assumed role session. Typically, you pass the
    #   name or identifier that is associated with the user who is using
    #   your application. That way, the temporary security credentials that
    #   your application will use are associated with that user. This
    #   session name is included as part of the ARN and assumed role ID in
    #   the `AssumedRoleUser` response element.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] web_identity_token
    #   The OAuth 2.0 access token or OpenID Connect ID token that is
    #   provided by the identity provider. Your application must get this
    #   token by authenticating the user who is using your application with
    #   a web identity provider before the application makes an
    #   `AssumeRoleWithWebIdentity` call. Only tokens with RSA algorithms
    #   (RS256) are supported.
    #   @return [String]
    #
    # @!attribute [rw] provider_id
    #   The fully qualified host component of the domain name of the OAuth
    #   2.0 identity provider. Do not specify this value for an OpenID
    #   Connect identity provider.
    #
    #   Currently `www.amazon.com` and `graph.facebook.com` are the only
    #   supported identity providers for OAuth 2.0 access tokens. Do not
    #   include URL schemes and port numbers.
    #
    #   Do not specify this value for OpenID Connect ID tokens.
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as managed session policies. The policies must exist
    #   in the same account as the role.
    #
    #   This parameter is optional. You can provide up to 10 managed policy
    #   ARNs. However, the plaintext that you use for both inline and
    #   managed session policies can't exceed 2,048 characters. For more
    #   information about ARNs, see [Amazon Resource Names (ARNs) and Amazon
    #   Web Services Service Namespaces][1] in the Amazon Web Services
    #   General Reference.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #   Passing policies to this operation returns new temporary
    #   credentials. The resulting session's permissions are the
    #   intersection of the role's identity-based policy and the session
    #   policies. You can use the role's temporary credentials in
    #   subsequent Amazon Web Services API calls to access resources in the
    #   account that owns the role. You cannot use session policies to grant
    #   more permissions than those allowed by the identity-based policy of
    #   the role that is being assumed. For more information, see [Session
    #   Policies][2] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   This parameter is optional. Passing policies to this operation
    #   returns new temporary credentials. The resulting session's
    #   permissions are the intersection of the role's identity-based
    #   policy and the session policies. You can use the role's temporary
    #   credentials in subsequent Amazon Web Services API calls to access
    #   resources in the account that owns the role. You cannot use session
    #   policies to grant more permissions than those allowed by the
    #   identity-based policy of the role that is being assumed. For more
    #   information, see [Session Policies][1] in the *IAM User Guide*.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of
    #   the valid character list (\\u0020 through \\u00FF). It can also
    #   include the tab (\\u0009), linefeed (\\u000A), and carriage return
    #   (\\u000D) characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, of the role session. The value can range
    #   from 900 seconds (15 minutes) up to the maximum session duration
    #   setting for the role. This setting can have a value from 1 hour to
    #   12 hours. If you specify a value higher than this setting, the
    #   operation fails. For example, if you specify a session duration of
    #   12 hours, but your administrator set the maximum session duration to
    #   6 hours, your operation fails. To learn how to view the maximum
    #   value for your role, see [View the Maximum Session Duration Setting
    #   for a Role][1] in the *IAM User Guide*.
    #
    #   By default, the value is set to `3600` seconds.
    #
    #   <note markdown="1"> The `DurationSeconds` parameter is separate from the duration of a
    #   console session that you might request using the returned
    #   credentials. The request to the federation endpoint for a console
    #   sign-in token takes a `SessionDuration` parameter that specifies the
    #   maximum length of the console session. For more information, see
    #   [Creating a URL that Enables Federated Users to Access the Amazon
    #   Web Services Management Console][2] in the *IAM User Guide*.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_enable-console-custom-url.html
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithWebIdentityRequest AWS API Documentation
    #
    class AssumeRoleWithWebIdentityRequest < Struct.new(
      :role_arn,
      :role_session_name,
      :web_identity_token,
      :provider_id,
      :policy_arns,
      :policy,
      :duration_seconds)
      SENSITIVE = [:web_identity_token]
      include Aws::Structure
    end

    # Contains the response to a successful AssumeRoleWithWebIdentity
    # request, including temporary Amazon Web Services credentials that can
    # be used to make Amazon Web Services requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] subject_from_web_identity_token
    #   The unique user identifier that is returned by the identity
    #   provider. This identifier is associated with the `WebIdentityToken`
    #   that was submitted with the `AssumeRoleWithWebIdentity` call. The
    #   identifier is typically unique to the user and the application that
    #   acquired the `WebIdentityToken` (pairwise identifier). For OpenID
    #   Connect ID tokens, this field contains the value returned by the
    #   identity provider as the token's `sub` (Subject) claim.
    #   @return [String]
    #
    # @!attribute [rw] assumed_role_user
    #   The Amazon Resource Name (ARN) and the assumed role ID, which are
    #   identifiers that you can use to refer to the resulting temporary
    #   security credentials. For example, you can reference these
    #   credentials as a principal in a resource-based policy by using the
    #   ARN or assumed role ID. The ARN and ID include the `RoleSessionName`
    #   that you specified when you called `AssumeRole`.
    #   @return [Types::AssumedRoleUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the packed size of the session
    #   policies and session tags combined passed in the request. The
    #   request fails if the packed size is greater than 100 percent, which
    #   means the policies and tags exceeded the allowed space.
    #   @return [Integer]
    #
    # @!attribute [rw] provider
    #   The issuing authority of the web identity token presented. For
    #   OpenID Connect ID tokens, this contains the value of the `iss`
    #   field. For OAuth 2.0 access tokens, this contains the value of the
    #   `ProviderId` parameter that was passed in the
    #   `AssumeRoleWithWebIdentity` request.
    #   @return [String]
    #
    # @!attribute [rw] audience
    #   The intended audience (also known as client ID) of the web identity
    #   token. This is traditionally the client identifier issued to the
    #   application that requested the web identity token.
    #   @return [String]
    #
    # @!attribute [rw] source_identity
    #   The value of the source identity that is returned in the JSON web
    #   token (JWT) from the identity provider.
    #
    #   You can require users to set a source identity value when they
    #   assume a role. You do this by using the `sts:SourceIdentity`
    #   condition key in a role trust policy. That way, actions that are
    #   taken with the role are associated with that user. After the source
    #   identity is set, the value cannot be changed. It is present in the
    #   request for all actions that are taken by the role and persists
    #   across [chained role][1] sessions. You can configure your identity
    #   provider to use an attribute associated with your users, like user
    #   name or email, as the source identity when calling
    #   `AssumeRoleWithWebIdentity`. You do this by adding a claim to the
    #   JSON web token. To learn more about OIDC tokens and claims, see
    #   [Using Tokens with User Pools][2] in the *Amazon Cognito Developer
    #   Guide*. For more information about using source identity, see
    #   [Monitor and control actions taken with assumed roles][3] in the
    #   *IAM User Guide*.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_terms-and-concepts#iam-term-role-chaining
    #   [2]: https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-with-identity-providers.html
    #   [3]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_control-access_monitor.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumeRoleWithWebIdentityResponse AWS API Documentation
    #
    class AssumeRoleWithWebIdentityResponse < Struct.new(
      :credentials,
      :subject_from_web_identity_token,
      :assumed_role_user,
      :packed_policy_size,
      :provider,
      :audience,
      :source_identity)
      SENSITIVE = []
      include Aws::Structure
    end

    # The identifiers for the temporary security credentials that the
    # operation returns.
    #
    # @!attribute [rw] assumed_role_id
    #   A unique identifier that contains the role ID and the role session
    #   name of the role that is being assumed. The role ID is generated by
    #   Amazon Web Services when the role is created.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The ARN of the temporary security credentials that are returned from
    #   the AssumeRole action. For more information about ARNs and how to
    #   use them in policies, see [IAM Identifiers][1] in the *IAM User
    #   Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/AssumedRoleUser AWS API Documentation
    #
    class AssumedRoleUser < Struct.new(
      :assumed_role_id,
      :arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Amazon Web Services credentials for API authentication.
    #
    # @!attribute [rw] access_key_id
    #   The access key ID that identifies the temporary security
    #   credentials.
    #   @return [String]
    #
    # @!attribute [rw] secret_access_key
    #   The secret access key that can be used to sign requests.
    #   @return [String]
    #
    # @!attribute [rw] session_token
    #   The token that users must pass to the service API to use the
    #   temporary credentials.
    #   @return [String]
    #
    # @!attribute [rw] expiration
    #   The date on which the current credentials expire.
    #   @return [Time]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/Credentials AWS API Documentation
    #
    class Credentials < Struct.new(
      :access_key_id,
      :secret_access_key,
      :session_token,
      :expiration)
      SENSITIVE = [:secret_access_key]
      include Aws::Structure
    end

    # @!attribute [rw] encoded_message
    #   The encoded message that was returned with the response.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/DecodeAuthorizationMessageRequest AWS API Documentation
    #
    class DecodeAuthorizationMessageRequest < Struct.new(
      :encoded_message)
      SENSITIVE = []
      include Aws::Structure
    end

    # A document that contains additional information about the
    # authorization status of a request from an encoded message that is
    # returned in response to an Amazon Web Services request.
    #
    # @!attribute [rw] decoded_message
    #   The API returns a response with the decoded message.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/DecodeAuthorizationMessageResponse AWS API Documentation
    #
    class DecodeAuthorizationMessageResponse < Struct.new(
      :decoded_message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The web identity token that was passed is expired or is not valid. Get
    # a new identity token from the identity provider and then retry the
    # request.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/ExpiredTokenException AWS API Documentation
    #
    class ExpiredTokenException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # Identifiers for the federated user that is associated with the
    # credentials.
    #
    # @!attribute [rw] federated_user_id
    #   The string that identifies the federated user associated with the
    #   credentials, similar to the unique ID of an IAM user.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The ARN that specifies the federated user that is associated with
    #   the credentials. For more information about ARNs and how to use them
    #   in policies, see [IAM Identifiers][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_identifiers.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/FederatedUser AWS API Documentation
    #
    class FederatedUser < Struct.new(
      :federated_user_id,
      :arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] access_key_id
    #   The identifier of an access key.
    #
    #   This parameter allows (through its regex pattern) a string of
    #   characters that can consist of any upper- or lowercase letter or
    #   digit.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetAccessKeyInfoRequest AWS API Documentation
    #
    class GetAccessKeyInfoRequest < Struct.new(
      :access_key_id)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] account
    #   The number used to identify the Amazon Web Services account.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetAccessKeyInfoResponse AWS API Documentation
    #
    class GetAccessKeyInfoResponse < Struct.new(
      :account)
      SENSITIVE = []
      include Aws::Structure
    end

    # @api private
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetCallerIdentityRequest AWS API Documentation
    #
    class GetCallerIdentityRequest < Aws::EmptyStructure; end

    # Contains the response to a successful GetCallerIdentity request,
    # including information about the entity making the request.
    #
    # @!attribute [rw] user_id
    #   The unique identifier of the calling entity. The exact value depends
    #   on the type of entity that is making the call. The values returned
    #   are those listed in the **aws:userid** column in the [Principal
    #   table][1] found on the **Policy Variables** reference page in the
    #   *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_variables.html#principaltable
    #   @return [String]
    #
    # @!attribute [rw] account
    #   The Amazon Web Services account ID number of the account that owns
    #   or contains the calling entity.
    #   @return [String]
    #
    # @!attribute [rw] arn
    #   The Amazon Web Services ARN associated with the calling entity.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetCallerIdentityResponse AWS API Documentation
    #
    class GetCallerIdentityResponse < Struct.new(
      :user_id,
      :account,
      :arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] name
    #   The name of the federated user. The name is used as an identifier
    #   for the temporary security credentials (such as `Bob`). For example,
    #   you can reference the federated user name in a resource-based
    #   policy, such as in an Amazon S3 bucket policy.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@-
    #   @return [String]
    #
    # @!attribute [rw] policy
    #   An IAM policy in JSON format that you want to use as an inline
    #   session policy.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed policy
    #   Amazon Resource Names (ARNs) to use as managed session policies.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions
    #   for a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][1] in the
    #   *IAM User Guide*.
    #
    #   The resulting credentials can be used to access a resource that has
    #   a resource-based policy. If that policy specifically references the
    #   federated user session in the `Principal` element of the policy, the
    #   session has the permissions allowed by the policy. These permissions
    #   are granted in addition to the permissions that are granted by the
    #   session policies.
    #
    #   The plaintext that you use for both inline and managed session
    #   policies can't exceed 2,048 characters. The JSON policy characters
    #   can be any ASCII character from the space character to the end of
    #   the valid character list (\\u0020 through \\u00FF). It can also
    #   include the tab (\\u0009), linefeed (\\u000A), and carriage return
    #   (\\u000D) characters.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   @return [String]
    #
    # @!attribute [rw] policy_arns
    #   The Amazon Resource Names (ARNs) of the IAM managed policies that
    #   you want to use as a managed session policy. The policies must exist
    #   in the same account as the IAM user that is requesting federated
    #   access.
    #
    #   You must pass an inline or managed [session policy][1] to this
    #   operation. You can pass a single JSON policy document to use as an
    #   inline session policy. You can also specify up to 10 managed policy
    #   Amazon Resource Names (ARNs) to use as managed session policies. The
    #   plaintext that you use for both inline and managed session policies
    #   can't exceed 2,048 characters. You can provide up to 10 managed
    #   policy ARNs. For more information about ARNs, see [Amazon Resource
    #   Names (ARNs) and Amazon Web Services Service Namespaces][2] in the
    #   Amazon Web Services General Reference.
    #
    #   This parameter is optional. However, if you do not pass any session
    #   policies, then the resulting federated user session has no
    #   permissions.
    #
    #   When you pass session policies, the session permissions are the
    #   intersection of the IAM user policies and the session policies that
    #   you pass. This gives you a way to further restrict the permissions
    #   for a federated user. You cannot use session policies to grant more
    #   permissions than those that are defined in the permissions policy of
    #   the IAM user. For more information, see [Session Policies][1] in the
    #   *IAM User Guide*.
    #
    #   The resulting credentials can be used to access a resource that has
    #   a resource-based policy. If that policy specifically references the
    #   federated user session in the `Principal` element of the policy, the
    #   session has the permissions allowed by the policy. These permissions
    #   are granted in addition to the permissions that are granted by the
    #   session policies.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html#policies_session
    #   [2]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   @return [Array<Types::PolicyDescriptorType>]
    #
    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, that the session should last. Acceptable
    #   durations for federation sessions range from 900 seconds (15
    #   minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12
    #   hours) as the default. Sessions obtained using root user credentials
    #   are restricted to a maximum of 3,600 seconds (one hour). If the
    #   specified duration is longer than one hour, the session obtained by
    #   using root user credentials defaults to one hour.
    #   @return [Integer]
    #
    # @!attribute [rw] tags
    #   A list of session tags. Each session tag consists of a key name and
    #   an associated value. For more information about session tags, see
    #   [Passing Session Tags in STS][1] in the *IAM User Guide*.
    #
    #   This parameter is optional. You can pass up to 50 session tags. The
    #   plaintext session tag keys can’t exceed 128 characters and the
    #   values can’t exceed 256 characters. For these and additional limits,
    #   see [IAM and STS Character Limits][2] in the *IAM User Guide*.
    #
    #   <note markdown="1"> An Amazon Web Services conversion compresses the passed inline
    #   session policy, managed policy ARNs, and session tags into a packed
    #   binary format that has a separate limit. Your request can fail for
    #   this limit even if your plaintext meets the other requirements. The
    #   `PackedPolicySize` response element indicates by percentage how
    #   close the policies and tags for your request are to the upper size
    #   limit.
    #
    #    </note>
    #
    #   You can pass a session tag with the same key as a tag that is
    #   already attached to the user you are federating. When you do,
    #   session tags override a user tag with the same key.
    #
    #   Tag key–value pairs are not case sensitive, but case is preserved.
    #   This means that you cannot have separate `Department` and
    #   `department` tag keys. Assume that the role has the
    #   `Department`=`Marketing` tag and you pass the
    #   `department`=`engineering` session tag. `Department` and
    #   `department` are not saved as separate tags, and the session tag
    #   passed in the request takes precedence over the role tag.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    #   [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    #   @return [Array<Types::Tag>]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetFederationTokenRequest AWS API Documentation
    #
    class GetFederationTokenRequest < Struct.new(
      :name,
      :policy,
      :policy_arns,
      :duration_seconds,
      :tags)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the response to a successful GetFederationToken request,
    # including temporary Amazon Web Services credentials that can be used
    # to make Amazon Web Services requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @!attribute [rw] federated_user
    #   Identifiers for the federated user associated with the credentials
    #   (such as `arn:aws:sts::123456789012:federated-user/Bob` or
    #   `123456789012:Bob`). You can use the federated user's ARN in your
    #   resource-based policies, such as an Amazon S3 bucket policy.
    #   @return [Types::FederatedUser]
    #
    # @!attribute [rw] packed_policy_size
    #   A percentage value that indicates the packed size of the session
    #   policies and session tags combined passed in the request. The
    #   request fails if the packed size is greater than 100 percent, which
    #   means the policies and tags exceeded the allowed space.
    #   @return [Integer]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetFederationTokenResponse AWS API Documentation
    #
    class GetFederationTokenResponse < Struct.new(
      :credentials,
      :federated_user,
      :packed_policy_size)
      SENSITIVE = []
      include Aws::Structure
    end

    # @!attribute [rw] duration_seconds
    #   The duration, in seconds, that the credentials should remain valid.
    #   Acceptable durations for IAM user sessions range from 900 seconds
    #   (15 minutes) to 129,600 seconds (36 hours), with 43,200 seconds (12
    #   hours) as the default. Sessions for Amazon Web Services account
    #   owners are restricted to a maximum of 3,600 seconds (one hour). If
    #   the duration is longer than one hour, the session for Amazon Web
    #   Services account owners defaults to one hour.
    #   @return [Integer]
    #
    # @!attribute [rw] serial_number
    #   The identification number of the MFA device that is associated with
    #   the IAM user who is making the `GetSessionToken` call. Specify this
    #   value if the IAM user has a policy that requires MFA authentication.
    #   The value is either the serial number for a hardware device (such as
    #   `GAHT12345678`) or an Amazon Resource Name (ARN) for a virtual
    #   device (such as `arn:aws:iam::123456789012:mfa/user`). You can find
    #   the device for an IAM user by going to the Amazon Web Services
    #   Management Console and viewing the user's security credentials.
    #
    #   The regex used to validate this parameter is a string of characters
    #   consisting of upper- and lower-case alphanumeric characters with no
    #   spaces. You can also include underscores or any of the following
    #   characters: =,.@:/-
    #   @return [String]
    #
    # @!attribute [rw] token_code
    #   The value provided by the MFA device, if MFA is required. If any
    #   policy requires the IAM user to submit an MFA code, specify this
    #   value. If MFA authentication is required, the user must provide a
    #   code when requesting a set of temporary security credentials. A user
    #   who fails to provide the code receives an "access denied" response
    #   when requesting resources that require MFA authentication.
    #
    #   The format for this parameter, as described by its regex pattern, is
    #   a sequence of six numeric digits.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetSessionTokenRequest AWS API Documentation
    #
    class GetSessionTokenRequest < Struct.new(
      :duration_seconds,
      :serial_number,
      :token_code)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains the response to a successful GetSessionToken request,
    # including temporary Amazon Web Services credentials that can be used
    # to make Amazon Web Services requests.
    #
    # @!attribute [rw] credentials
    #   The temporary security credentials, which include an access key ID,
    #   a secret access key, and a security (or session) token.
    #
    #   <note markdown="1"> The size of the security token that STS API operations return is not
    #   fixed. We strongly recommend that you make no assumptions about the
    #   maximum size.
    #
    #    </note>
    #   @return [Types::Credentials]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/GetSessionTokenResponse AWS API Documentation
    #
    class GetSessionTokenResponse < Struct.new(
      :credentials)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request could not be fulfilled because the identity provider (IDP)
    # that was asked to verify the incoming identity token could not be
    # reached. This is often a transient error caused by network conditions.
    # Retry the request a limited number of times so that you don't exceed
    # the request rate. If the error persists, the identity provider might
    # be down or not responding.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/IDPCommunicationErrorException AWS API Documentation
    #
    class IDPCommunicationErrorException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The identity provider (IdP) reported that authentication failed. This
    # might be because the claim is invalid.
    #
    # If this error is returned for the `AssumeRoleWithWebIdentity`
    # operation, it can also mean that the claim has expired or has been
    # explicitly revoked.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/IDPRejectedClaimException AWS API Documentation
    #
    class IDPRejectedClaimException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The error returned if the message passed to
    # `DecodeAuthorizationMessage` was invalid. This can happen if the token
    # contains invalid characters, such as linebreaks.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/InvalidAuthorizationMessageException AWS API Documentation
    #
    class InvalidAuthorizationMessageException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The web identity token that was passed could not be validated by
    # Amazon Web Services. Get a new identity token from the identity
    # provider and then retry the request.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/InvalidIdentityTokenException AWS API Documentation
    #
    class InvalidIdentityTokenException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request was rejected because the policy document was malformed.
    # The error message describes the specific error.
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/MalformedPolicyDocumentException AWS API Documentation
    #
    class MalformedPolicyDocumentException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # The request was rejected because the total packed size of the session
    # policies and session tags combined was too large. An Amazon Web
    # Services conversion compresses the session policy document, session
    # policy ARNs, and session tags into a packed binary format that has a
    # separate limit. The error message indicates by percentage how close
    # the policies and tags are to the upper size limit. For more
    # information, see [Passing Session Tags in STS][1] in the *IAM User
    # Guide*.
    #
    # You could receive this error even though you meet other defined
    # session policy and session tag limits. For more information, see [IAM
    # and STS Entity Character Limits][2] in the *IAM User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    # [2]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html#reference_iam-limits-entity-length
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/PackedPolicyTooLargeException AWS API Documentation
    #
    class PackedPolicyTooLargeException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # A reference to the IAM managed policy that is passed as a session
    # policy for a role session or a federated user session.
    #
    # @!attribute [rw] arn
    #   The Amazon Resource Name (ARN) of the IAM managed policy to use as a
    #   session policy for the role. For more information about ARNs, see
    #   [Amazon Resource Names (ARNs) and Amazon Web Services Service
    #   Namespaces][1] in the *Amazon Web Services General Reference*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/PolicyDescriptorType AWS API Documentation
    #
    class PolicyDescriptorType < Struct.new(
      :arn)
      SENSITIVE = []
      include Aws::Structure
    end

    # Contains information about the provided context. This includes the
    # signed and encrypted trusted context assertion and the context
    # provider ARN from which the trusted context assertion was generated.
    #
    # @!attribute [rw] provider_arn
    #   The context provider ARN from which the trusted context assertion
    #   was generated.
    #   @return [String]
    #
    # @!attribute [rw] context_assertion
    #   The signed and encrypted trusted context assertion generated by the
    #   context provider. The trusted context assertion is signed and
    #   encrypted by Amazon Web Services STS.
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/ProvidedContext AWS API Documentation
    #
    class ProvidedContext < Struct.new(
      :provider_arn,
      :context_assertion)
      SENSITIVE = []
      include Aws::Structure
    end

    # STS is not activated in the requested region for the account that is
    # being asked to generate credentials. The account administrator must
    # use the IAM console to activate STS in that region. For more
    # information, see [Activating and Deactivating Amazon Web Services STS
    # in an Amazon Web Services Region][1] in the *IAM User Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_enable-regions.html
    #
    # @!attribute [rw] message
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/RegionDisabledException AWS API Documentation
    #
    class RegionDisabledException < Struct.new(
      :message)
      SENSITIVE = []
      include Aws::Structure
    end

    # You can pass custom key-value pair attributes when you assume a role
    # or federate a user. These are called session tags. You can then use
    # the session tags to control access to resources. For more information,
    # see [Tagging Amazon Web Services STS Sessions][1] in the *IAM User
    # Guide*.
    #
    #
    #
    # [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html
    #
    # @!attribute [rw] key
    #   The key for a session tag.
    #
    #   You can pass up to 50 session tags. The plain text session tag keys
    #   can’t exceed 128 characters. For these and additional limits, see
    #   [IAM and STS Character Limits][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    #   @return [String]
    #
    # @!attribute [rw] value
    #   The value for a session tag.
    #
    #   You can pass up to 50 session tags. The plain text session tag
    #   values can’t exceed 256 characters. For these and additional limits,
    #   see [IAM and STS Character Limits][1] in the *IAM User Guide*.
    #
    #
    #
    #   [1]: https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-limits.html#reference_iam-limits-entity-length
    #   @return [String]
    #
    # @see http://docs.aws.amazon.com/goto/WebAPI/sts-2011-06-15/Tag AWS API Documentation
    #
    class Tag < Struct.new(
      :key,
      :value)
      SENSITIVE = []
      include Aws::Structure
    end

  end
end
