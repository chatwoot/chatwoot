# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::STS
  # @api private
  module ClientApi

    include Seahorse::Model

    AssumeRoleRequest = Shapes::StructureShape.new(name: 'AssumeRoleRequest')
    AssumeRoleResponse = Shapes::StructureShape.new(name: 'AssumeRoleResponse')
    AssumeRoleWithSAMLRequest = Shapes::StructureShape.new(name: 'AssumeRoleWithSAMLRequest')
    AssumeRoleWithSAMLResponse = Shapes::StructureShape.new(name: 'AssumeRoleWithSAMLResponse')
    AssumeRoleWithWebIdentityRequest = Shapes::StructureShape.new(name: 'AssumeRoleWithWebIdentityRequest')
    AssumeRoleWithWebIdentityResponse = Shapes::StructureShape.new(name: 'AssumeRoleWithWebIdentityResponse')
    AssumedRoleUser = Shapes::StructureShape.new(name: 'AssumedRoleUser')
    Audience = Shapes::StringShape.new(name: 'Audience')
    Credentials = Shapes::StructureShape.new(name: 'Credentials')
    DecodeAuthorizationMessageRequest = Shapes::StructureShape.new(name: 'DecodeAuthorizationMessageRequest')
    DecodeAuthorizationMessageResponse = Shapes::StructureShape.new(name: 'DecodeAuthorizationMessageResponse')
    ExpiredTokenException = Shapes::StructureShape.new(name: 'ExpiredTokenException')
    FederatedUser = Shapes::StructureShape.new(name: 'FederatedUser')
    GetAccessKeyInfoRequest = Shapes::StructureShape.new(name: 'GetAccessKeyInfoRequest')
    GetAccessKeyInfoResponse = Shapes::StructureShape.new(name: 'GetAccessKeyInfoResponse')
    GetCallerIdentityRequest = Shapes::StructureShape.new(name: 'GetCallerIdentityRequest')
    GetCallerIdentityResponse = Shapes::StructureShape.new(name: 'GetCallerIdentityResponse')
    GetFederationTokenRequest = Shapes::StructureShape.new(name: 'GetFederationTokenRequest')
    GetFederationTokenResponse = Shapes::StructureShape.new(name: 'GetFederationTokenResponse')
    GetSessionTokenRequest = Shapes::StructureShape.new(name: 'GetSessionTokenRequest')
    GetSessionTokenResponse = Shapes::StructureShape.new(name: 'GetSessionTokenResponse')
    IDPCommunicationErrorException = Shapes::StructureShape.new(name: 'IDPCommunicationErrorException')
    IDPRejectedClaimException = Shapes::StructureShape.new(name: 'IDPRejectedClaimException')
    InvalidAuthorizationMessageException = Shapes::StructureShape.new(name: 'InvalidAuthorizationMessageException')
    InvalidIdentityTokenException = Shapes::StructureShape.new(name: 'InvalidIdentityTokenException')
    Issuer = Shapes::StringShape.new(name: 'Issuer')
    MalformedPolicyDocumentException = Shapes::StructureShape.new(name: 'MalformedPolicyDocumentException')
    NameQualifier = Shapes::StringShape.new(name: 'NameQualifier')
    PackedPolicyTooLargeException = Shapes::StructureShape.new(name: 'PackedPolicyTooLargeException')
    PolicyDescriptorType = Shapes::StructureShape.new(name: 'PolicyDescriptorType')
    ProvidedContext = Shapes::StructureShape.new(name: 'ProvidedContext')
    ProvidedContextsListType = Shapes::ListShape.new(name: 'ProvidedContextsListType')
    RegionDisabledException = Shapes::StructureShape.new(name: 'RegionDisabledException')
    SAMLAssertionType = Shapes::StringShape.new(name: 'SAMLAssertionType')
    Subject = Shapes::StringShape.new(name: 'Subject')
    SubjectType = Shapes::StringShape.new(name: 'SubjectType')
    Tag = Shapes::StructureShape.new(name: 'Tag')
    accessKeyIdType = Shapes::StringShape.new(name: 'accessKeyIdType')
    accessKeySecretType = Shapes::StringShape.new(name: 'accessKeySecretType')
    accountType = Shapes::StringShape.new(name: 'accountType')
    arnType = Shapes::StringShape.new(name: 'arnType')
    assumedRoleIdType = Shapes::StringShape.new(name: 'assumedRoleIdType')
    clientTokenType = Shapes::StringShape.new(name: 'clientTokenType')
    contextAssertionType = Shapes::StringShape.new(name: 'contextAssertionType')
    dateType = Shapes::TimestampShape.new(name: 'dateType')
    decodedMessageType = Shapes::StringShape.new(name: 'decodedMessageType')
    durationSecondsType = Shapes::IntegerShape.new(name: 'durationSecondsType')
    encodedMessageType = Shapes::StringShape.new(name: 'encodedMessageType')
    expiredIdentityTokenMessage = Shapes::StringShape.new(name: 'expiredIdentityTokenMessage')
    externalIdType = Shapes::StringShape.new(name: 'externalIdType')
    federatedIdType = Shapes::StringShape.new(name: 'federatedIdType')
    idpCommunicationErrorMessage = Shapes::StringShape.new(name: 'idpCommunicationErrorMessage')
    idpRejectedClaimMessage = Shapes::StringShape.new(name: 'idpRejectedClaimMessage')
    invalidAuthorizationMessage = Shapes::StringShape.new(name: 'invalidAuthorizationMessage')
    invalidIdentityTokenMessage = Shapes::StringShape.new(name: 'invalidIdentityTokenMessage')
    malformedPolicyDocumentMessage = Shapes::StringShape.new(name: 'malformedPolicyDocumentMessage')
    nonNegativeIntegerType = Shapes::IntegerShape.new(name: 'nonNegativeIntegerType')
    packedPolicyTooLargeMessage = Shapes::StringShape.new(name: 'packedPolicyTooLargeMessage')
    policyDescriptorListType = Shapes::ListShape.new(name: 'policyDescriptorListType')
    regionDisabledMessage = Shapes::StringShape.new(name: 'regionDisabledMessage')
    roleDurationSecondsType = Shapes::IntegerShape.new(name: 'roleDurationSecondsType')
    roleSessionNameType = Shapes::StringShape.new(name: 'roleSessionNameType')
    serialNumberType = Shapes::StringShape.new(name: 'serialNumberType')
    sessionPolicyDocumentType = Shapes::StringShape.new(name: 'sessionPolicyDocumentType')
    sourceIdentityType = Shapes::StringShape.new(name: 'sourceIdentityType')
    tagKeyListType = Shapes::ListShape.new(name: 'tagKeyListType')
    tagKeyType = Shapes::StringShape.new(name: 'tagKeyType')
    tagListType = Shapes::ListShape.new(name: 'tagListType')
    tagValueType = Shapes::StringShape.new(name: 'tagValueType')
    tokenCodeType = Shapes::StringShape.new(name: 'tokenCodeType')
    tokenType = Shapes::StringShape.new(name: 'tokenType')
    unrestrictedSessionPolicyDocumentType = Shapes::StringShape.new(name: 'unrestrictedSessionPolicyDocumentType')
    urlType = Shapes::StringShape.new(name: 'urlType')
    userIdType = Shapes::StringShape.new(name: 'userIdType')
    userNameType = Shapes::StringShape.new(name: 'userNameType')
    webIdentitySubjectType = Shapes::StringShape.new(name: 'webIdentitySubjectType')

    AssumeRoleRequest.add_member(:role_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "RoleArn"))
    AssumeRoleRequest.add_member(:role_session_name, Shapes::ShapeRef.new(shape: roleSessionNameType, required: true, location_name: "RoleSessionName"))
    AssumeRoleRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    AssumeRoleRequest.add_member(:policy, Shapes::ShapeRef.new(shape: unrestrictedSessionPolicyDocumentType, location_name: "Policy"))
    AssumeRoleRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: roleDurationSecondsType, location_name: "DurationSeconds"))
    AssumeRoleRequest.add_member(:tags, Shapes::ShapeRef.new(shape: tagListType, location_name: "Tags"))
    AssumeRoleRequest.add_member(:transitive_tag_keys, Shapes::ShapeRef.new(shape: tagKeyListType, location_name: "TransitiveTagKeys"))
    AssumeRoleRequest.add_member(:external_id, Shapes::ShapeRef.new(shape: externalIdType, location_name: "ExternalId"))
    AssumeRoleRequest.add_member(:serial_number, Shapes::ShapeRef.new(shape: serialNumberType, location_name: "SerialNumber"))
    AssumeRoleRequest.add_member(:token_code, Shapes::ShapeRef.new(shape: tokenCodeType, location_name: "TokenCode"))
    AssumeRoleRequest.add_member(:source_identity, Shapes::ShapeRef.new(shape: sourceIdentityType, location_name: "SourceIdentity"))
    AssumeRoleRequest.add_member(:provided_contexts, Shapes::ShapeRef.new(shape: ProvidedContextsListType, location_name: "ProvidedContexts"))
    AssumeRoleRequest.struct_class = Types::AssumeRoleRequest

    AssumeRoleResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    AssumeRoleResponse.add_member(:assumed_role_user, Shapes::ShapeRef.new(shape: AssumedRoleUser, location_name: "AssumedRoleUser"))
    AssumeRoleResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    AssumeRoleResponse.add_member(:source_identity, Shapes::ShapeRef.new(shape: sourceIdentityType, location_name: "SourceIdentity"))
    AssumeRoleResponse.struct_class = Types::AssumeRoleResponse

    AssumeRoleWithSAMLRequest.add_member(:role_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "RoleArn"))
    AssumeRoleWithSAMLRequest.add_member(:principal_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "PrincipalArn"))
    AssumeRoleWithSAMLRequest.add_member(:saml_assertion, Shapes::ShapeRef.new(shape: SAMLAssertionType, required: true, location_name: "SAMLAssertion"))
    AssumeRoleWithSAMLRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    AssumeRoleWithSAMLRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    AssumeRoleWithSAMLRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: roleDurationSecondsType, location_name: "DurationSeconds"))
    AssumeRoleWithSAMLRequest.struct_class = Types::AssumeRoleWithSAMLRequest

    AssumeRoleWithSAMLResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    AssumeRoleWithSAMLResponse.add_member(:assumed_role_user, Shapes::ShapeRef.new(shape: AssumedRoleUser, location_name: "AssumedRoleUser"))
    AssumeRoleWithSAMLResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    AssumeRoleWithSAMLResponse.add_member(:subject, Shapes::ShapeRef.new(shape: Subject, location_name: "Subject"))
    AssumeRoleWithSAMLResponse.add_member(:subject_type, Shapes::ShapeRef.new(shape: SubjectType, location_name: "SubjectType"))
    AssumeRoleWithSAMLResponse.add_member(:issuer, Shapes::ShapeRef.new(shape: Issuer, location_name: "Issuer"))
    AssumeRoleWithSAMLResponse.add_member(:audience, Shapes::ShapeRef.new(shape: Audience, location_name: "Audience"))
    AssumeRoleWithSAMLResponse.add_member(:name_qualifier, Shapes::ShapeRef.new(shape: NameQualifier, location_name: "NameQualifier"))
    AssumeRoleWithSAMLResponse.add_member(:source_identity, Shapes::ShapeRef.new(shape: sourceIdentityType, location_name: "SourceIdentity"))
    AssumeRoleWithSAMLResponse.struct_class = Types::AssumeRoleWithSAMLResponse

    AssumeRoleWithWebIdentityRequest.add_member(:role_arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "RoleArn"))
    AssumeRoleWithWebIdentityRequest.add_member(:role_session_name, Shapes::ShapeRef.new(shape: roleSessionNameType, required: true, location_name: "RoleSessionName"))
    AssumeRoleWithWebIdentityRequest.add_member(:web_identity_token, Shapes::ShapeRef.new(shape: clientTokenType, required: true, location_name: "WebIdentityToken"))
    AssumeRoleWithWebIdentityRequest.add_member(:provider_id, Shapes::ShapeRef.new(shape: urlType, location_name: "ProviderId"))
    AssumeRoleWithWebIdentityRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    AssumeRoleWithWebIdentityRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    AssumeRoleWithWebIdentityRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: roleDurationSecondsType, location_name: "DurationSeconds"))
    AssumeRoleWithWebIdentityRequest.struct_class = Types::AssumeRoleWithWebIdentityRequest

    AssumeRoleWithWebIdentityResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    AssumeRoleWithWebIdentityResponse.add_member(:subject_from_web_identity_token, Shapes::ShapeRef.new(shape: webIdentitySubjectType, location_name: "SubjectFromWebIdentityToken"))
    AssumeRoleWithWebIdentityResponse.add_member(:assumed_role_user, Shapes::ShapeRef.new(shape: AssumedRoleUser, location_name: "AssumedRoleUser"))
    AssumeRoleWithWebIdentityResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    AssumeRoleWithWebIdentityResponse.add_member(:provider, Shapes::ShapeRef.new(shape: Issuer, location_name: "Provider"))
    AssumeRoleWithWebIdentityResponse.add_member(:audience, Shapes::ShapeRef.new(shape: Audience, location_name: "Audience"))
    AssumeRoleWithWebIdentityResponse.add_member(:source_identity, Shapes::ShapeRef.new(shape: sourceIdentityType, location_name: "SourceIdentity"))
    AssumeRoleWithWebIdentityResponse.struct_class = Types::AssumeRoleWithWebIdentityResponse

    AssumedRoleUser.add_member(:assumed_role_id, Shapes::ShapeRef.new(shape: assumedRoleIdType, required: true, location_name: "AssumedRoleId"))
    AssumedRoleUser.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "Arn"))
    AssumedRoleUser.struct_class = Types::AssumedRoleUser

    Credentials.add_member(:access_key_id, Shapes::ShapeRef.new(shape: accessKeyIdType, required: true, location_name: "AccessKeyId"))
    Credentials.add_member(:secret_access_key, Shapes::ShapeRef.new(shape: accessKeySecretType, required: true, location_name: "SecretAccessKey"))
    Credentials.add_member(:session_token, Shapes::ShapeRef.new(shape: tokenType, required: true, location_name: "SessionToken"))
    Credentials.add_member(:expiration, Shapes::ShapeRef.new(shape: dateType, required: true, location_name: "Expiration"))
    Credentials.struct_class = Types::Credentials

    DecodeAuthorizationMessageRequest.add_member(:encoded_message, Shapes::ShapeRef.new(shape: encodedMessageType, required: true, location_name: "EncodedMessage"))
    DecodeAuthorizationMessageRequest.struct_class = Types::DecodeAuthorizationMessageRequest

    DecodeAuthorizationMessageResponse.add_member(:decoded_message, Shapes::ShapeRef.new(shape: decodedMessageType, location_name: "DecodedMessage"))
    DecodeAuthorizationMessageResponse.struct_class = Types::DecodeAuthorizationMessageResponse

    ExpiredTokenException.add_member(:message, Shapes::ShapeRef.new(shape: expiredIdentityTokenMessage, location_name: "message"))
    ExpiredTokenException.struct_class = Types::ExpiredTokenException

    FederatedUser.add_member(:federated_user_id, Shapes::ShapeRef.new(shape: federatedIdType, required: true, location_name: "FederatedUserId"))
    FederatedUser.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, required: true, location_name: "Arn"))
    FederatedUser.struct_class = Types::FederatedUser

    GetAccessKeyInfoRequest.add_member(:access_key_id, Shapes::ShapeRef.new(shape: accessKeyIdType, required: true, location_name: "AccessKeyId"))
    GetAccessKeyInfoRequest.struct_class = Types::GetAccessKeyInfoRequest

    GetAccessKeyInfoResponse.add_member(:account, Shapes::ShapeRef.new(shape: accountType, location_name: "Account"))
    GetAccessKeyInfoResponse.struct_class = Types::GetAccessKeyInfoResponse

    GetCallerIdentityRequest.struct_class = Types::GetCallerIdentityRequest

    GetCallerIdentityResponse.add_member(:user_id, Shapes::ShapeRef.new(shape: userIdType, location_name: "UserId"))
    GetCallerIdentityResponse.add_member(:account, Shapes::ShapeRef.new(shape: accountType, location_name: "Account"))
    GetCallerIdentityResponse.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, location_name: "Arn"))
    GetCallerIdentityResponse.struct_class = Types::GetCallerIdentityResponse

    GetFederationTokenRequest.add_member(:name, Shapes::ShapeRef.new(shape: userNameType, required: true, location_name: "Name"))
    GetFederationTokenRequest.add_member(:policy, Shapes::ShapeRef.new(shape: sessionPolicyDocumentType, location_name: "Policy"))
    GetFederationTokenRequest.add_member(:policy_arns, Shapes::ShapeRef.new(shape: policyDescriptorListType, location_name: "PolicyArns"))
    GetFederationTokenRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: durationSecondsType, location_name: "DurationSeconds"))
    GetFederationTokenRequest.add_member(:tags, Shapes::ShapeRef.new(shape: tagListType, location_name: "Tags"))
    GetFederationTokenRequest.struct_class = Types::GetFederationTokenRequest

    GetFederationTokenResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    GetFederationTokenResponse.add_member(:federated_user, Shapes::ShapeRef.new(shape: FederatedUser, location_name: "FederatedUser"))
    GetFederationTokenResponse.add_member(:packed_policy_size, Shapes::ShapeRef.new(shape: nonNegativeIntegerType, location_name: "PackedPolicySize"))
    GetFederationTokenResponse.struct_class = Types::GetFederationTokenResponse

    GetSessionTokenRequest.add_member(:duration_seconds, Shapes::ShapeRef.new(shape: durationSecondsType, location_name: "DurationSeconds"))
    GetSessionTokenRequest.add_member(:serial_number, Shapes::ShapeRef.new(shape: serialNumberType, location_name: "SerialNumber"))
    GetSessionTokenRequest.add_member(:token_code, Shapes::ShapeRef.new(shape: tokenCodeType, location_name: "TokenCode"))
    GetSessionTokenRequest.struct_class = Types::GetSessionTokenRequest

    GetSessionTokenResponse.add_member(:credentials, Shapes::ShapeRef.new(shape: Credentials, location_name: "Credentials"))
    GetSessionTokenResponse.struct_class = Types::GetSessionTokenResponse

    IDPCommunicationErrorException.add_member(:message, Shapes::ShapeRef.new(shape: idpCommunicationErrorMessage, location_name: "message"))
    IDPCommunicationErrorException.struct_class = Types::IDPCommunicationErrorException

    IDPRejectedClaimException.add_member(:message, Shapes::ShapeRef.new(shape: idpRejectedClaimMessage, location_name: "message"))
    IDPRejectedClaimException.struct_class = Types::IDPRejectedClaimException

    InvalidAuthorizationMessageException.add_member(:message, Shapes::ShapeRef.new(shape: invalidAuthorizationMessage, location_name: "message"))
    InvalidAuthorizationMessageException.struct_class = Types::InvalidAuthorizationMessageException

    InvalidIdentityTokenException.add_member(:message, Shapes::ShapeRef.new(shape: invalidIdentityTokenMessage, location_name: "message"))
    InvalidIdentityTokenException.struct_class = Types::InvalidIdentityTokenException

    MalformedPolicyDocumentException.add_member(:message, Shapes::ShapeRef.new(shape: malformedPolicyDocumentMessage, location_name: "message"))
    MalformedPolicyDocumentException.struct_class = Types::MalformedPolicyDocumentException

    PackedPolicyTooLargeException.add_member(:message, Shapes::ShapeRef.new(shape: packedPolicyTooLargeMessage, location_name: "message"))
    PackedPolicyTooLargeException.struct_class = Types::PackedPolicyTooLargeException

    PolicyDescriptorType.add_member(:arn, Shapes::ShapeRef.new(shape: arnType, location_name: "arn"))
    PolicyDescriptorType.struct_class = Types::PolicyDescriptorType

    ProvidedContext.add_member(:provider_arn, Shapes::ShapeRef.new(shape: arnType, location_name: "ProviderArn"))
    ProvidedContext.add_member(:context_assertion, Shapes::ShapeRef.new(shape: contextAssertionType, location_name: "ContextAssertion"))
    ProvidedContext.struct_class = Types::ProvidedContext

    ProvidedContextsListType.member = Shapes::ShapeRef.new(shape: ProvidedContext)

    RegionDisabledException.add_member(:message, Shapes::ShapeRef.new(shape: regionDisabledMessage, location_name: "message"))
    RegionDisabledException.struct_class = Types::RegionDisabledException

    Tag.add_member(:key, Shapes::ShapeRef.new(shape: tagKeyType, required: true, location_name: "Key"))
    Tag.add_member(:value, Shapes::ShapeRef.new(shape: tagValueType, required: true, location_name: "Value"))
    Tag.struct_class = Types::Tag

    policyDescriptorListType.member = Shapes::ShapeRef.new(shape: PolicyDescriptorType)

    tagKeyListType.member = Shapes::ShapeRef.new(shape: tagKeyType)

    tagListType.member = Shapes::ShapeRef.new(shape: Tag)


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2011-06-15"

      api.metadata = {
        "apiVersion" => "2011-06-15",
        "endpointPrefix" => "sts",
        "globalEndpoint" => "sts.amazonaws.com",
        "protocol" => "query",
        "serviceAbbreviation" => "AWS STS",
        "serviceFullName" => "AWS Security Token Service",
        "serviceId" => "STS",
        "signatureVersion" => "v4",
        "uid" => "sts-2011-06-15",
        "xmlNamespace" => "https://sts.amazonaws.com/doc/2011-06-15/",
      }

      api.add_operation(:assume_role, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AssumeRole"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: AssumeRoleRequest)
        o.output = Shapes::ShapeRef.new(shape: AssumeRoleResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
      end)

      api.add_operation(:assume_role_with_saml, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AssumeRoleWithSAML"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: AssumeRoleWithSAMLRequest)
        o.output = Shapes::ShapeRef.new(shape: AssumeRoleWithSAMLResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: IDPRejectedClaimException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidIdentityTokenException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:assume_role_with_web_identity, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AssumeRoleWithWebIdentity"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o['authtype'] = "none"
        o.input = Shapes::ShapeRef.new(shape: AssumeRoleWithWebIdentityRequest)
        o.output = Shapes::ShapeRef.new(shape: AssumeRoleWithWebIdentityResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: IDPRejectedClaimException)
        o.errors << Shapes::ShapeRef.new(shape: IDPCommunicationErrorException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidIdentityTokenException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredTokenException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:decode_authorization_message, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DecodeAuthorizationMessage"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DecodeAuthorizationMessageRequest)
        o.output = Shapes::ShapeRef.new(shape: DecodeAuthorizationMessageResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidAuthorizationMessageException)
      end)

      api.add_operation(:get_access_key_info, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetAccessKeyInfo"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetAccessKeyInfoRequest)
        o.output = Shapes::ShapeRef.new(shape: GetAccessKeyInfoResponse)
      end)

      api.add_operation(:get_caller_identity, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetCallerIdentity"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetCallerIdentityRequest)
        o.output = Shapes::ShapeRef.new(shape: GetCallerIdentityResponse)
      end)

      api.add_operation(:get_federation_token, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetFederationToken"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetFederationTokenRequest)
        o.output = Shapes::ShapeRef.new(shape: GetFederationTokenResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: PackedPolicyTooLargeException)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)

      api.add_operation(:get_session_token, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetSessionToken"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetSessionTokenRequest)
        o.output = Shapes::ShapeRef.new(shape: GetSessionTokenResponse)
        o.errors << Shapes::ShapeRef.new(shape: RegionDisabledException)
      end)
    end

  end
end
