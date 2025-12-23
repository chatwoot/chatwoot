# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::KMS
  # @api private
  module ClientApi

    include Seahorse::Model

    AWSAccountIdType = Shapes::StringShape.new(name: 'AWSAccountIdType')
    AlgorithmSpec = Shapes::StringShape.new(name: 'AlgorithmSpec')
    AliasList = Shapes::ListShape.new(name: 'AliasList')
    AliasListEntry = Shapes::StructureShape.new(name: 'AliasListEntry')
    AliasNameType = Shapes::StringShape.new(name: 'AliasNameType')
    AlreadyExistsException = Shapes::StructureShape.new(name: 'AlreadyExistsException')
    ArnType = Shapes::StringShape.new(name: 'ArnType')
    AttestationDocumentType = Shapes::BlobShape.new(name: 'AttestationDocumentType')
    BooleanType = Shapes::BooleanShape.new(name: 'BooleanType')
    CancelKeyDeletionRequest = Shapes::StructureShape.new(name: 'CancelKeyDeletionRequest')
    CancelKeyDeletionResponse = Shapes::StructureShape.new(name: 'CancelKeyDeletionResponse')
    CiphertextType = Shapes::BlobShape.new(name: 'CiphertextType')
    CloudHsmClusterIdType = Shapes::StringShape.new(name: 'CloudHsmClusterIdType')
    CloudHsmClusterInUseException = Shapes::StructureShape.new(name: 'CloudHsmClusterInUseException')
    CloudHsmClusterInvalidConfigurationException = Shapes::StructureShape.new(name: 'CloudHsmClusterInvalidConfigurationException')
    CloudHsmClusterNotActiveException = Shapes::StructureShape.new(name: 'CloudHsmClusterNotActiveException')
    CloudHsmClusterNotFoundException = Shapes::StructureShape.new(name: 'CloudHsmClusterNotFoundException')
    CloudHsmClusterNotRelatedException = Shapes::StructureShape.new(name: 'CloudHsmClusterNotRelatedException')
    ConnectCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'ConnectCustomKeyStoreRequest')
    ConnectCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'ConnectCustomKeyStoreResponse')
    ConnectionErrorCodeType = Shapes::StringShape.new(name: 'ConnectionErrorCodeType')
    ConnectionStateType = Shapes::StringShape.new(name: 'ConnectionStateType')
    CreateAliasRequest = Shapes::StructureShape.new(name: 'CreateAliasRequest')
    CreateCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'CreateCustomKeyStoreRequest')
    CreateCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'CreateCustomKeyStoreResponse')
    CreateGrantRequest = Shapes::StructureShape.new(name: 'CreateGrantRequest')
    CreateGrantResponse = Shapes::StructureShape.new(name: 'CreateGrantResponse')
    CreateKeyRequest = Shapes::StructureShape.new(name: 'CreateKeyRequest')
    CreateKeyResponse = Shapes::StructureShape.new(name: 'CreateKeyResponse')
    CustomKeyStoreHasCMKsException = Shapes::StructureShape.new(name: 'CustomKeyStoreHasCMKsException')
    CustomKeyStoreIdType = Shapes::StringShape.new(name: 'CustomKeyStoreIdType')
    CustomKeyStoreInvalidStateException = Shapes::StructureShape.new(name: 'CustomKeyStoreInvalidStateException')
    CustomKeyStoreNameInUseException = Shapes::StructureShape.new(name: 'CustomKeyStoreNameInUseException')
    CustomKeyStoreNameType = Shapes::StringShape.new(name: 'CustomKeyStoreNameType')
    CustomKeyStoreNotFoundException = Shapes::StructureShape.new(name: 'CustomKeyStoreNotFoundException')
    CustomKeyStoreType = Shapes::StringShape.new(name: 'CustomKeyStoreType')
    CustomKeyStoresList = Shapes::ListShape.new(name: 'CustomKeyStoresList')
    CustomKeyStoresListEntry = Shapes::StructureShape.new(name: 'CustomKeyStoresListEntry')
    CustomerMasterKeySpec = Shapes::StringShape.new(name: 'CustomerMasterKeySpec')
    DataKeyPairSpec = Shapes::StringShape.new(name: 'DataKeyPairSpec')
    DataKeySpec = Shapes::StringShape.new(name: 'DataKeySpec')
    DateType = Shapes::TimestampShape.new(name: 'DateType')
    DecryptRequest = Shapes::StructureShape.new(name: 'DecryptRequest')
    DecryptResponse = Shapes::StructureShape.new(name: 'DecryptResponse')
    DeleteAliasRequest = Shapes::StructureShape.new(name: 'DeleteAliasRequest')
    DeleteCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'DeleteCustomKeyStoreRequest')
    DeleteCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'DeleteCustomKeyStoreResponse')
    DeleteImportedKeyMaterialRequest = Shapes::StructureShape.new(name: 'DeleteImportedKeyMaterialRequest')
    DependencyTimeoutException = Shapes::StructureShape.new(name: 'DependencyTimeoutException')
    DescribeCustomKeyStoresRequest = Shapes::StructureShape.new(name: 'DescribeCustomKeyStoresRequest')
    DescribeCustomKeyStoresResponse = Shapes::StructureShape.new(name: 'DescribeCustomKeyStoresResponse')
    DescribeKeyRequest = Shapes::StructureShape.new(name: 'DescribeKeyRequest')
    DescribeKeyResponse = Shapes::StructureShape.new(name: 'DescribeKeyResponse')
    DescriptionType = Shapes::StringShape.new(name: 'DescriptionType')
    DisableKeyRequest = Shapes::StructureShape.new(name: 'DisableKeyRequest')
    DisableKeyRotationRequest = Shapes::StructureShape.new(name: 'DisableKeyRotationRequest')
    DisabledException = Shapes::StructureShape.new(name: 'DisabledException')
    DisconnectCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'DisconnectCustomKeyStoreRequest')
    DisconnectCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'DisconnectCustomKeyStoreResponse')
    EnableKeyRequest = Shapes::StructureShape.new(name: 'EnableKeyRequest')
    EnableKeyRotationRequest = Shapes::StructureShape.new(name: 'EnableKeyRotationRequest')
    EncryptRequest = Shapes::StructureShape.new(name: 'EncryptRequest')
    EncryptResponse = Shapes::StructureShape.new(name: 'EncryptResponse')
    EncryptionAlgorithmSpec = Shapes::StringShape.new(name: 'EncryptionAlgorithmSpec')
    EncryptionAlgorithmSpecList = Shapes::ListShape.new(name: 'EncryptionAlgorithmSpecList')
    EncryptionContextKey = Shapes::StringShape.new(name: 'EncryptionContextKey')
    EncryptionContextType = Shapes::MapShape.new(name: 'EncryptionContextType')
    EncryptionContextValue = Shapes::StringShape.new(name: 'EncryptionContextValue')
    ErrorMessageType = Shapes::StringShape.new(name: 'ErrorMessageType')
    ExpirationModelType = Shapes::StringShape.new(name: 'ExpirationModelType')
    ExpiredImportTokenException = Shapes::StructureShape.new(name: 'ExpiredImportTokenException')
    GenerateDataKeyPairRequest = Shapes::StructureShape.new(name: 'GenerateDataKeyPairRequest')
    GenerateDataKeyPairResponse = Shapes::StructureShape.new(name: 'GenerateDataKeyPairResponse')
    GenerateDataKeyPairWithoutPlaintextRequest = Shapes::StructureShape.new(name: 'GenerateDataKeyPairWithoutPlaintextRequest')
    GenerateDataKeyPairWithoutPlaintextResponse = Shapes::StructureShape.new(name: 'GenerateDataKeyPairWithoutPlaintextResponse')
    GenerateDataKeyRequest = Shapes::StructureShape.new(name: 'GenerateDataKeyRequest')
    GenerateDataKeyResponse = Shapes::StructureShape.new(name: 'GenerateDataKeyResponse')
    GenerateDataKeyWithoutPlaintextRequest = Shapes::StructureShape.new(name: 'GenerateDataKeyWithoutPlaintextRequest')
    GenerateDataKeyWithoutPlaintextResponse = Shapes::StructureShape.new(name: 'GenerateDataKeyWithoutPlaintextResponse')
    GenerateMacRequest = Shapes::StructureShape.new(name: 'GenerateMacRequest')
    GenerateMacResponse = Shapes::StructureShape.new(name: 'GenerateMacResponse')
    GenerateRandomRequest = Shapes::StructureShape.new(name: 'GenerateRandomRequest')
    GenerateRandomResponse = Shapes::StructureShape.new(name: 'GenerateRandomResponse')
    GetKeyPolicyRequest = Shapes::StructureShape.new(name: 'GetKeyPolicyRequest')
    GetKeyPolicyResponse = Shapes::StructureShape.new(name: 'GetKeyPolicyResponse')
    GetKeyRotationStatusRequest = Shapes::StructureShape.new(name: 'GetKeyRotationStatusRequest')
    GetKeyRotationStatusResponse = Shapes::StructureShape.new(name: 'GetKeyRotationStatusResponse')
    GetParametersForImportRequest = Shapes::StructureShape.new(name: 'GetParametersForImportRequest')
    GetParametersForImportResponse = Shapes::StructureShape.new(name: 'GetParametersForImportResponse')
    GetPublicKeyRequest = Shapes::StructureShape.new(name: 'GetPublicKeyRequest')
    GetPublicKeyResponse = Shapes::StructureShape.new(name: 'GetPublicKeyResponse')
    GrantConstraints = Shapes::StructureShape.new(name: 'GrantConstraints')
    GrantIdType = Shapes::StringShape.new(name: 'GrantIdType')
    GrantList = Shapes::ListShape.new(name: 'GrantList')
    GrantListEntry = Shapes::StructureShape.new(name: 'GrantListEntry')
    GrantNameType = Shapes::StringShape.new(name: 'GrantNameType')
    GrantOperation = Shapes::StringShape.new(name: 'GrantOperation')
    GrantOperationList = Shapes::ListShape.new(name: 'GrantOperationList')
    GrantTokenList = Shapes::ListShape.new(name: 'GrantTokenList')
    GrantTokenType = Shapes::StringShape.new(name: 'GrantTokenType')
    ImportKeyMaterialRequest = Shapes::StructureShape.new(name: 'ImportKeyMaterialRequest')
    ImportKeyMaterialResponse = Shapes::StructureShape.new(name: 'ImportKeyMaterialResponse')
    IncorrectKeyException = Shapes::StructureShape.new(name: 'IncorrectKeyException')
    IncorrectKeyMaterialException = Shapes::StructureShape.new(name: 'IncorrectKeyMaterialException')
    IncorrectTrustAnchorException = Shapes::StructureShape.new(name: 'IncorrectTrustAnchorException')
    InvalidAliasNameException = Shapes::StructureShape.new(name: 'InvalidAliasNameException')
    InvalidArnException = Shapes::StructureShape.new(name: 'InvalidArnException')
    InvalidCiphertextException = Shapes::StructureShape.new(name: 'InvalidCiphertextException')
    InvalidGrantIdException = Shapes::StructureShape.new(name: 'InvalidGrantIdException')
    InvalidGrantTokenException = Shapes::StructureShape.new(name: 'InvalidGrantTokenException')
    InvalidImportTokenException = Shapes::StructureShape.new(name: 'InvalidImportTokenException')
    InvalidKeyUsageException = Shapes::StructureShape.new(name: 'InvalidKeyUsageException')
    InvalidMarkerException = Shapes::StructureShape.new(name: 'InvalidMarkerException')
    KMSInternalException = Shapes::StructureShape.new(name: 'KMSInternalException')
    KMSInvalidMacException = Shapes::StructureShape.new(name: 'KMSInvalidMacException')
    KMSInvalidSignatureException = Shapes::StructureShape.new(name: 'KMSInvalidSignatureException')
    KMSInvalidStateException = Shapes::StructureShape.new(name: 'KMSInvalidStateException')
    KeyEncryptionMechanism = Shapes::StringShape.new(name: 'KeyEncryptionMechanism')
    KeyIdType = Shapes::StringShape.new(name: 'KeyIdType')
    KeyList = Shapes::ListShape.new(name: 'KeyList')
    KeyListEntry = Shapes::StructureShape.new(name: 'KeyListEntry')
    KeyManagerType = Shapes::StringShape.new(name: 'KeyManagerType')
    KeyMetadata = Shapes::StructureShape.new(name: 'KeyMetadata')
    KeySpec = Shapes::StringShape.new(name: 'KeySpec')
    KeyState = Shapes::StringShape.new(name: 'KeyState')
    KeyStorePasswordType = Shapes::StringShape.new(name: 'KeyStorePasswordType')
    KeyUnavailableException = Shapes::StructureShape.new(name: 'KeyUnavailableException')
    KeyUsageType = Shapes::StringShape.new(name: 'KeyUsageType')
    LimitExceededException = Shapes::StructureShape.new(name: 'LimitExceededException')
    LimitType = Shapes::IntegerShape.new(name: 'LimitType')
    ListAliasesRequest = Shapes::StructureShape.new(name: 'ListAliasesRequest')
    ListAliasesResponse = Shapes::StructureShape.new(name: 'ListAliasesResponse')
    ListGrantsRequest = Shapes::StructureShape.new(name: 'ListGrantsRequest')
    ListGrantsResponse = Shapes::StructureShape.new(name: 'ListGrantsResponse')
    ListKeyPoliciesRequest = Shapes::StructureShape.new(name: 'ListKeyPoliciesRequest')
    ListKeyPoliciesResponse = Shapes::StructureShape.new(name: 'ListKeyPoliciesResponse')
    ListKeysRequest = Shapes::StructureShape.new(name: 'ListKeysRequest')
    ListKeysResponse = Shapes::StructureShape.new(name: 'ListKeysResponse')
    ListResourceTagsRequest = Shapes::StructureShape.new(name: 'ListResourceTagsRequest')
    ListResourceTagsResponse = Shapes::StructureShape.new(name: 'ListResourceTagsResponse')
    ListRetirableGrantsRequest = Shapes::StructureShape.new(name: 'ListRetirableGrantsRequest')
    MacAlgorithmSpec = Shapes::StringShape.new(name: 'MacAlgorithmSpec')
    MacAlgorithmSpecList = Shapes::ListShape.new(name: 'MacAlgorithmSpecList')
    MalformedPolicyDocumentException = Shapes::StructureShape.new(name: 'MalformedPolicyDocumentException')
    MarkerType = Shapes::StringShape.new(name: 'MarkerType')
    MessageType = Shapes::StringShape.new(name: 'MessageType')
    MultiRegionConfiguration = Shapes::StructureShape.new(name: 'MultiRegionConfiguration')
    MultiRegionKey = Shapes::StructureShape.new(name: 'MultiRegionKey')
    MultiRegionKeyList = Shapes::ListShape.new(name: 'MultiRegionKeyList')
    MultiRegionKeyType = Shapes::StringShape.new(name: 'MultiRegionKeyType')
    NotFoundException = Shapes::StructureShape.new(name: 'NotFoundException')
    NullableBooleanType = Shapes::BooleanShape.new(name: 'NullableBooleanType')
    NumberOfBytesType = Shapes::IntegerShape.new(name: 'NumberOfBytesType')
    OriginType = Shapes::StringShape.new(name: 'OriginType')
    PendingWindowInDaysType = Shapes::IntegerShape.new(name: 'PendingWindowInDaysType')
    PlaintextType = Shapes::BlobShape.new(name: 'PlaintextType')
    PolicyNameList = Shapes::ListShape.new(name: 'PolicyNameList')
    PolicyNameType = Shapes::StringShape.new(name: 'PolicyNameType')
    PolicyType = Shapes::StringShape.new(name: 'PolicyType')
    PrincipalIdType = Shapes::StringShape.new(name: 'PrincipalIdType')
    PublicKeyType = Shapes::BlobShape.new(name: 'PublicKeyType')
    PutKeyPolicyRequest = Shapes::StructureShape.new(name: 'PutKeyPolicyRequest')
    ReEncryptRequest = Shapes::StructureShape.new(name: 'ReEncryptRequest')
    ReEncryptResponse = Shapes::StructureShape.new(name: 'ReEncryptResponse')
    RecipientInfo = Shapes::StructureShape.new(name: 'RecipientInfo')
    RegionType = Shapes::StringShape.new(name: 'RegionType')
    ReplicateKeyRequest = Shapes::StructureShape.new(name: 'ReplicateKeyRequest')
    ReplicateKeyResponse = Shapes::StructureShape.new(name: 'ReplicateKeyResponse')
    RetireGrantRequest = Shapes::StructureShape.new(name: 'RetireGrantRequest')
    RevokeGrantRequest = Shapes::StructureShape.new(name: 'RevokeGrantRequest')
    ScheduleKeyDeletionRequest = Shapes::StructureShape.new(name: 'ScheduleKeyDeletionRequest')
    ScheduleKeyDeletionResponse = Shapes::StructureShape.new(name: 'ScheduleKeyDeletionResponse')
    SignRequest = Shapes::StructureShape.new(name: 'SignRequest')
    SignResponse = Shapes::StructureShape.new(name: 'SignResponse')
    SigningAlgorithmSpec = Shapes::StringShape.new(name: 'SigningAlgorithmSpec')
    SigningAlgorithmSpecList = Shapes::ListShape.new(name: 'SigningAlgorithmSpecList')
    Tag = Shapes::StructureShape.new(name: 'Tag')
    TagException = Shapes::StructureShape.new(name: 'TagException')
    TagKeyList = Shapes::ListShape.new(name: 'TagKeyList')
    TagKeyType = Shapes::StringShape.new(name: 'TagKeyType')
    TagList = Shapes::ListShape.new(name: 'TagList')
    TagResourceRequest = Shapes::StructureShape.new(name: 'TagResourceRequest')
    TagValueType = Shapes::StringShape.new(name: 'TagValueType')
    TrustAnchorCertificateType = Shapes::StringShape.new(name: 'TrustAnchorCertificateType')
    UnsupportedOperationException = Shapes::StructureShape.new(name: 'UnsupportedOperationException')
    UntagResourceRequest = Shapes::StructureShape.new(name: 'UntagResourceRequest')
    UpdateAliasRequest = Shapes::StructureShape.new(name: 'UpdateAliasRequest')
    UpdateCustomKeyStoreRequest = Shapes::StructureShape.new(name: 'UpdateCustomKeyStoreRequest')
    UpdateCustomKeyStoreResponse = Shapes::StructureShape.new(name: 'UpdateCustomKeyStoreResponse')
    UpdateKeyDescriptionRequest = Shapes::StructureShape.new(name: 'UpdateKeyDescriptionRequest')
    UpdatePrimaryRegionRequest = Shapes::StructureShape.new(name: 'UpdatePrimaryRegionRequest')
    VerifyMacRequest = Shapes::StructureShape.new(name: 'VerifyMacRequest')
    VerifyMacResponse = Shapes::StructureShape.new(name: 'VerifyMacResponse')
    VerifyRequest = Shapes::StructureShape.new(name: 'VerifyRequest')
    VerifyResponse = Shapes::StructureShape.new(name: 'VerifyResponse')
    WrappingKeySpec = Shapes::StringShape.new(name: 'WrappingKeySpec')
    XksKeyAlreadyInUseException = Shapes::StructureShape.new(name: 'XksKeyAlreadyInUseException')
    XksKeyConfigurationType = Shapes::StructureShape.new(name: 'XksKeyConfigurationType')
    XksKeyIdType = Shapes::StringShape.new(name: 'XksKeyIdType')
    XksKeyInvalidConfigurationException = Shapes::StructureShape.new(name: 'XksKeyInvalidConfigurationException')
    XksKeyNotFoundException = Shapes::StructureShape.new(name: 'XksKeyNotFoundException')
    XksProxyAuthenticationAccessKeyIdType = Shapes::StringShape.new(name: 'XksProxyAuthenticationAccessKeyIdType')
    XksProxyAuthenticationCredentialType = Shapes::StructureShape.new(name: 'XksProxyAuthenticationCredentialType')
    XksProxyAuthenticationRawSecretAccessKeyType = Shapes::StringShape.new(name: 'XksProxyAuthenticationRawSecretAccessKeyType')
    XksProxyConfigurationType = Shapes::StructureShape.new(name: 'XksProxyConfigurationType')
    XksProxyConnectivityType = Shapes::StringShape.new(name: 'XksProxyConnectivityType')
    XksProxyIncorrectAuthenticationCredentialException = Shapes::StructureShape.new(name: 'XksProxyIncorrectAuthenticationCredentialException')
    XksProxyInvalidConfigurationException = Shapes::StructureShape.new(name: 'XksProxyInvalidConfigurationException')
    XksProxyInvalidResponseException = Shapes::StructureShape.new(name: 'XksProxyInvalidResponseException')
    XksProxyUriEndpointInUseException = Shapes::StructureShape.new(name: 'XksProxyUriEndpointInUseException')
    XksProxyUriEndpointType = Shapes::StringShape.new(name: 'XksProxyUriEndpointType')
    XksProxyUriInUseException = Shapes::StructureShape.new(name: 'XksProxyUriInUseException')
    XksProxyUriPathType = Shapes::StringShape.new(name: 'XksProxyUriPathType')
    XksProxyUriUnreachableException = Shapes::StructureShape.new(name: 'XksProxyUriUnreachableException')
    XksProxyVpcEndpointServiceInUseException = Shapes::StructureShape.new(name: 'XksProxyVpcEndpointServiceInUseException')
    XksProxyVpcEndpointServiceInvalidConfigurationException = Shapes::StructureShape.new(name: 'XksProxyVpcEndpointServiceInvalidConfigurationException')
    XksProxyVpcEndpointServiceNameType = Shapes::StringShape.new(name: 'XksProxyVpcEndpointServiceNameType')
    XksProxyVpcEndpointServiceNotFoundException = Shapes::StructureShape.new(name: 'XksProxyVpcEndpointServiceNotFoundException')

    AliasList.member = Shapes::ShapeRef.new(shape: AliasListEntry)

    AliasListEntry.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, location_name: "AliasName"))
    AliasListEntry.add_member(:alias_arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "AliasArn"))
    AliasListEntry.add_member(:target_key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "TargetKeyId"))
    AliasListEntry.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    AliasListEntry.add_member(:last_updated_date, Shapes::ShapeRef.new(shape: DateType, location_name: "LastUpdatedDate"))
    AliasListEntry.struct_class = Types::AliasListEntry

    AlreadyExistsException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    AlreadyExistsException.struct_class = Types::AlreadyExistsException

    CancelKeyDeletionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    CancelKeyDeletionRequest.struct_class = Types::CancelKeyDeletionRequest

    CancelKeyDeletionResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    CancelKeyDeletionResponse.struct_class = Types::CancelKeyDeletionResponse

    CloudHsmClusterInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterInUseException.struct_class = Types::CloudHsmClusterInUseException

    CloudHsmClusterInvalidConfigurationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterInvalidConfigurationException.struct_class = Types::CloudHsmClusterInvalidConfigurationException

    CloudHsmClusterNotActiveException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterNotActiveException.struct_class = Types::CloudHsmClusterNotActiveException

    CloudHsmClusterNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterNotFoundException.struct_class = Types::CloudHsmClusterNotFoundException

    CloudHsmClusterNotRelatedException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CloudHsmClusterNotRelatedException.struct_class = Types::CloudHsmClusterNotRelatedException

    ConnectCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    ConnectCustomKeyStoreRequest.struct_class = Types::ConnectCustomKeyStoreRequest

    ConnectCustomKeyStoreResponse.struct_class = Types::ConnectCustomKeyStoreResponse

    CreateAliasRequest.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, required: true, location_name: "AliasName"))
    CreateAliasRequest.add_member(:target_key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "TargetKeyId"))
    CreateAliasRequest.struct_class = Types::CreateAliasRequest

    CreateCustomKeyStoreRequest.add_member(:custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, required: true, location_name: "CustomKeyStoreName"))
    CreateCustomKeyStoreRequest.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    CreateCustomKeyStoreRequest.add_member(:trust_anchor_certificate, Shapes::ShapeRef.new(shape: TrustAnchorCertificateType, location_name: "TrustAnchorCertificate"))
    CreateCustomKeyStoreRequest.add_member(:key_store_password, Shapes::ShapeRef.new(shape: KeyStorePasswordType, location_name: "KeyStorePassword"))
    CreateCustomKeyStoreRequest.add_member(:custom_key_store_type, Shapes::ShapeRef.new(shape: CustomKeyStoreType, location_name: "CustomKeyStoreType"))
    CreateCustomKeyStoreRequest.add_member(:xks_proxy_uri_endpoint, Shapes::ShapeRef.new(shape: XksProxyUriEndpointType, location_name: "XksProxyUriEndpoint"))
    CreateCustomKeyStoreRequest.add_member(:xks_proxy_uri_path, Shapes::ShapeRef.new(shape: XksProxyUriPathType, location_name: "XksProxyUriPath"))
    CreateCustomKeyStoreRequest.add_member(:xks_proxy_vpc_endpoint_service_name, Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceNameType, location_name: "XksProxyVpcEndpointServiceName"))
    CreateCustomKeyStoreRequest.add_member(:xks_proxy_authentication_credential, Shapes::ShapeRef.new(shape: XksProxyAuthenticationCredentialType, location_name: "XksProxyAuthenticationCredential"))
    CreateCustomKeyStoreRequest.add_member(:xks_proxy_connectivity, Shapes::ShapeRef.new(shape: XksProxyConnectivityType, location_name: "XksProxyConnectivity"))
    CreateCustomKeyStoreRequest.struct_class = Types::CreateCustomKeyStoreRequest

    CreateCustomKeyStoreResponse.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    CreateCustomKeyStoreResponse.struct_class = Types::CreateCustomKeyStoreResponse

    CreateGrantRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    CreateGrantRequest.add_member(:grantee_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, required: true, location_name: "GranteePrincipal"))
    CreateGrantRequest.add_member(:retiring_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "RetiringPrincipal"))
    CreateGrantRequest.add_member(:operations, Shapes::ShapeRef.new(shape: GrantOperationList, required: true, location_name: "Operations"))
    CreateGrantRequest.add_member(:constraints, Shapes::ShapeRef.new(shape: GrantConstraints, location_name: "Constraints"))
    CreateGrantRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    CreateGrantRequest.add_member(:name, Shapes::ShapeRef.new(shape: GrantNameType, location_name: "Name"))
    CreateGrantRequest.struct_class = Types::CreateGrantRequest

    CreateGrantResponse.add_member(:grant_token, Shapes::ShapeRef.new(shape: GrantTokenType, location_name: "GrantToken"))
    CreateGrantResponse.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    CreateGrantResponse.struct_class = Types::CreateGrantResponse

    CreateKeyRequest.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, location_name: "Policy"))
    CreateKeyRequest.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, location_name: "Description"))
    CreateKeyRequest.add_member(:key_usage, Shapes::ShapeRef.new(shape: KeyUsageType, location_name: "KeyUsage"))
    CreateKeyRequest.add_member(:customer_master_key_spec, Shapes::ShapeRef.new(shape: CustomerMasterKeySpec, deprecated: true, location_name: "CustomerMasterKeySpec", metadata: {"deprecatedMessage"=>"This parameter has been deprecated. Instead, use the KeySpec parameter."}))
    CreateKeyRequest.add_member(:key_spec, Shapes::ShapeRef.new(shape: KeySpec, location_name: "KeySpec"))
    CreateKeyRequest.add_member(:origin, Shapes::ShapeRef.new(shape: OriginType, location_name: "Origin"))
    CreateKeyRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    CreateKeyRequest.add_member(:bypass_policy_lockout_safety_check, Shapes::ShapeRef.new(shape: BooleanType, location_name: "BypassPolicyLockoutSafetyCheck"))
    CreateKeyRequest.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    CreateKeyRequest.add_member(:multi_region, Shapes::ShapeRef.new(shape: NullableBooleanType, location_name: "MultiRegion"))
    CreateKeyRequest.add_member(:xks_key_id, Shapes::ShapeRef.new(shape: XksKeyIdType, location_name: "XksKeyId"))
    CreateKeyRequest.struct_class = Types::CreateKeyRequest

    CreateKeyResponse.add_member(:key_metadata, Shapes::ShapeRef.new(shape: KeyMetadata, location_name: "KeyMetadata"))
    CreateKeyResponse.struct_class = Types::CreateKeyResponse

    CustomKeyStoreHasCMKsException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreHasCMKsException.struct_class = Types::CustomKeyStoreHasCMKsException

    CustomKeyStoreInvalidStateException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreInvalidStateException.struct_class = Types::CustomKeyStoreInvalidStateException

    CustomKeyStoreNameInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreNameInUseException.struct_class = Types::CustomKeyStoreNameInUseException

    CustomKeyStoreNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    CustomKeyStoreNotFoundException.struct_class = Types::CustomKeyStoreNotFoundException

    CustomKeyStoresList.member = Shapes::ShapeRef.new(shape: CustomKeyStoresListEntry)

    CustomKeyStoresListEntry.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    CustomKeyStoresListEntry.add_member(:custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, location_name: "CustomKeyStoreName"))
    CustomKeyStoresListEntry.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    CustomKeyStoresListEntry.add_member(:trust_anchor_certificate, Shapes::ShapeRef.new(shape: TrustAnchorCertificateType, location_name: "TrustAnchorCertificate"))
    CustomKeyStoresListEntry.add_member(:connection_state, Shapes::ShapeRef.new(shape: ConnectionStateType, location_name: "ConnectionState"))
    CustomKeyStoresListEntry.add_member(:connection_error_code, Shapes::ShapeRef.new(shape: ConnectionErrorCodeType, location_name: "ConnectionErrorCode"))
    CustomKeyStoresListEntry.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    CustomKeyStoresListEntry.add_member(:custom_key_store_type, Shapes::ShapeRef.new(shape: CustomKeyStoreType, location_name: "CustomKeyStoreType"))
    CustomKeyStoresListEntry.add_member(:xks_proxy_configuration, Shapes::ShapeRef.new(shape: XksProxyConfigurationType, location_name: "XksProxyConfiguration"))
    CustomKeyStoresListEntry.struct_class = Types::CustomKeyStoresListEntry

    DecryptRequest.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "CiphertextBlob"))
    DecryptRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    DecryptRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    DecryptRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    DecryptRequest.add_member(:encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "EncryptionAlgorithm"))
    DecryptRequest.add_member(:recipient, Shapes::ShapeRef.new(shape: RecipientInfo, location_name: "Recipient"))
    DecryptRequest.struct_class = Types::DecryptRequest

    DecryptResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    DecryptResponse.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "Plaintext"))
    DecryptResponse.add_member(:encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "EncryptionAlgorithm"))
    DecryptResponse.add_member(:ciphertext_for_recipient, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextForRecipient"))
    DecryptResponse.struct_class = Types::DecryptResponse

    DeleteAliasRequest.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, required: true, location_name: "AliasName"))
    DeleteAliasRequest.struct_class = Types::DeleteAliasRequest

    DeleteCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    DeleteCustomKeyStoreRequest.struct_class = Types::DeleteCustomKeyStoreRequest

    DeleteCustomKeyStoreResponse.struct_class = Types::DeleteCustomKeyStoreResponse

    DeleteImportedKeyMaterialRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DeleteImportedKeyMaterialRequest.struct_class = Types::DeleteImportedKeyMaterialRequest

    DependencyTimeoutException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    DependencyTimeoutException.struct_class = Types::DependencyTimeoutException

    DescribeCustomKeyStoresRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    DescribeCustomKeyStoresRequest.add_member(:custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, location_name: "CustomKeyStoreName"))
    DescribeCustomKeyStoresRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    DescribeCustomKeyStoresRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    DescribeCustomKeyStoresRequest.struct_class = Types::DescribeCustomKeyStoresRequest

    DescribeCustomKeyStoresResponse.add_member(:custom_key_stores, Shapes::ShapeRef.new(shape: CustomKeyStoresList, location_name: "CustomKeyStores"))
    DescribeCustomKeyStoresResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    DescribeCustomKeyStoresResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    DescribeCustomKeyStoresResponse.struct_class = Types::DescribeCustomKeyStoresResponse

    DescribeKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DescribeKeyRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    DescribeKeyRequest.struct_class = Types::DescribeKeyRequest

    DescribeKeyResponse.add_member(:key_metadata, Shapes::ShapeRef.new(shape: KeyMetadata, location_name: "KeyMetadata"))
    DescribeKeyResponse.struct_class = Types::DescribeKeyResponse

    DisableKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DisableKeyRequest.struct_class = Types::DisableKeyRequest

    DisableKeyRotationRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    DisableKeyRotationRequest.struct_class = Types::DisableKeyRotationRequest

    DisabledException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    DisabledException.struct_class = Types::DisabledException

    DisconnectCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    DisconnectCustomKeyStoreRequest.struct_class = Types::DisconnectCustomKeyStoreRequest

    DisconnectCustomKeyStoreResponse.struct_class = Types::DisconnectCustomKeyStoreResponse

    EnableKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    EnableKeyRequest.struct_class = Types::EnableKeyRequest

    EnableKeyRotationRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    EnableKeyRotationRequest.struct_class = Types::EnableKeyRotationRequest

    EncryptRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    EncryptRequest.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, required: true, location_name: "Plaintext"))
    EncryptRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    EncryptRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    EncryptRequest.add_member(:encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "EncryptionAlgorithm"))
    EncryptRequest.struct_class = Types::EncryptRequest

    EncryptResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    EncryptResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    EncryptResponse.add_member(:encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "EncryptionAlgorithm"))
    EncryptResponse.struct_class = Types::EncryptResponse

    EncryptionAlgorithmSpecList.member = Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec)

    EncryptionContextType.key = Shapes::ShapeRef.new(shape: EncryptionContextKey)
    EncryptionContextType.value = Shapes::ShapeRef.new(shape: EncryptionContextValue)

    ExpiredImportTokenException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    ExpiredImportTokenException.struct_class = Types::ExpiredImportTokenException

    GenerateDataKeyPairRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    GenerateDataKeyPairRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateDataKeyPairRequest.add_member(:key_pair_spec, Shapes::ShapeRef.new(shape: DataKeyPairSpec, required: true, location_name: "KeyPairSpec"))
    GenerateDataKeyPairRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateDataKeyPairRequest.add_member(:recipient, Shapes::ShapeRef.new(shape: RecipientInfo, location_name: "Recipient"))
    GenerateDataKeyPairRequest.struct_class = Types::GenerateDataKeyPairRequest

    GenerateDataKeyPairResponse.add_member(:private_key_ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "PrivateKeyCiphertextBlob"))
    GenerateDataKeyPairResponse.add_member(:private_key_plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "PrivateKeyPlaintext"))
    GenerateDataKeyPairResponse.add_member(:public_key, Shapes::ShapeRef.new(shape: PublicKeyType, location_name: "PublicKey"))
    GenerateDataKeyPairResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateDataKeyPairResponse.add_member(:key_pair_spec, Shapes::ShapeRef.new(shape: DataKeyPairSpec, location_name: "KeyPairSpec"))
    GenerateDataKeyPairResponse.add_member(:ciphertext_for_recipient, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextForRecipient"))
    GenerateDataKeyPairResponse.struct_class = Types::GenerateDataKeyPairResponse

    GenerateDataKeyPairWithoutPlaintextRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    GenerateDataKeyPairWithoutPlaintextRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateDataKeyPairWithoutPlaintextRequest.add_member(:key_pair_spec, Shapes::ShapeRef.new(shape: DataKeyPairSpec, required: true, location_name: "KeyPairSpec"))
    GenerateDataKeyPairWithoutPlaintextRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateDataKeyPairWithoutPlaintextRequest.struct_class = Types::GenerateDataKeyPairWithoutPlaintextRequest

    GenerateDataKeyPairWithoutPlaintextResponse.add_member(:private_key_ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "PrivateKeyCiphertextBlob"))
    GenerateDataKeyPairWithoutPlaintextResponse.add_member(:public_key, Shapes::ShapeRef.new(shape: PublicKeyType, location_name: "PublicKey"))
    GenerateDataKeyPairWithoutPlaintextResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateDataKeyPairWithoutPlaintextResponse.add_member(:key_pair_spec, Shapes::ShapeRef.new(shape: DataKeyPairSpec, location_name: "KeyPairSpec"))
    GenerateDataKeyPairWithoutPlaintextResponse.struct_class = Types::GenerateDataKeyPairWithoutPlaintextResponse

    GenerateDataKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateDataKeyRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    GenerateDataKeyRequest.add_member(:number_of_bytes, Shapes::ShapeRef.new(shape: NumberOfBytesType, location_name: "NumberOfBytes"))
    GenerateDataKeyRequest.add_member(:key_spec, Shapes::ShapeRef.new(shape: DataKeySpec, location_name: "KeySpec"))
    GenerateDataKeyRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateDataKeyRequest.add_member(:recipient, Shapes::ShapeRef.new(shape: RecipientInfo, location_name: "Recipient"))
    GenerateDataKeyRequest.struct_class = Types::GenerateDataKeyRequest

    GenerateDataKeyResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    GenerateDataKeyResponse.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "Plaintext"))
    GenerateDataKeyResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateDataKeyResponse.add_member(:ciphertext_for_recipient, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextForRecipient"))
    GenerateDataKeyResponse.struct_class = Types::GenerateDataKeyResponse

    GenerateDataKeyWithoutPlaintextRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContext"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:key_spec, Shapes::ShapeRef.new(shape: DataKeySpec, location_name: "KeySpec"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:number_of_bytes, Shapes::ShapeRef.new(shape: NumberOfBytesType, location_name: "NumberOfBytes"))
    GenerateDataKeyWithoutPlaintextRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateDataKeyWithoutPlaintextRequest.struct_class = Types::GenerateDataKeyWithoutPlaintextRequest

    GenerateDataKeyWithoutPlaintextResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    GenerateDataKeyWithoutPlaintextResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateDataKeyWithoutPlaintextResponse.struct_class = Types::GenerateDataKeyWithoutPlaintextResponse

    GenerateMacRequest.add_member(:message, Shapes::ShapeRef.new(shape: PlaintextType, required: true, location_name: "Message"))
    GenerateMacRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GenerateMacRequest.add_member(:mac_algorithm, Shapes::ShapeRef.new(shape: MacAlgorithmSpec, required: true, location_name: "MacAlgorithm"))
    GenerateMacRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GenerateMacRequest.struct_class = Types::GenerateMacRequest

    GenerateMacResponse.add_member(:mac, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "Mac"))
    GenerateMacResponse.add_member(:mac_algorithm, Shapes::ShapeRef.new(shape: MacAlgorithmSpec, location_name: "MacAlgorithm"))
    GenerateMacResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GenerateMacResponse.struct_class = Types::GenerateMacResponse

    GenerateRandomRequest.add_member(:number_of_bytes, Shapes::ShapeRef.new(shape: NumberOfBytesType, location_name: "NumberOfBytes"))
    GenerateRandomRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    GenerateRandomRequest.add_member(:recipient, Shapes::ShapeRef.new(shape: RecipientInfo, location_name: "Recipient"))
    GenerateRandomRequest.struct_class = Types::GenerateRandomRequest

    GenerateRandomResponse.add_member(:plaintext, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "Plaintext"))
    GenerateRandomResponse.add_member(:ciphertext_for_recipient, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextForRecipient"))
    GenerateRandomResponse.struct_class = Types::GenerateRandomResponse

    GetKeyPolicyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetKeyPolicyRequest.add_member(:policy_name, Shapes::ShapeRef.new(shape: PolicyNameType, required: true, location_name: "PolicyName"))
    GetKeyPolicyRequest.struct_class = Types::GetKeyPolicyRequest

    GetKeyPolicyResponse.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, location_name: "Policy"))
    GetKeyPolicyResponse.struct_class = Types::GetKeyPolicyResponse

    GetKeyRotationStatusRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetKeyRotationStatusRequest.struct_class = Types::GetKeyRotationStatusRequest

    GetKeyRotationStatusResponse.add_member(:key_rotation_enabled, Shapes::ShapeRef.new(shape: BooleanType, location_name: "KeyRotationEnabled"))
    GetKeyRotationStatusResponse.struct_class = Types::GetKeyRotationStatusResponse

    GetParametersForImportRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetParametersForImportRequest.add_member(:wrapping_algorithm, Shapes::ShapeRef.new(shape: AlgorithmSpec, required: true, location_name: "WrappingAlgorithm"))
    GetParametersForImportRequest.add_member(:wrapping_key_spec, Shapes::ShapeRef.new(shape: WrappingKeySpec, required: true, location_name: "WrappingKeySpec"))
    GetParametersForImportRequest.struct_class = Types::GetParametersForImportRequest

    GetParametersForImportResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GetParametersForImportResponse.add_member(:import_token, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "ImportToken"))
    GetParametersForImportResponse.add_member(:public_key, Shapes::ShapeRef.new(shape: PlaintextType, location_name: "PublicKey"))
    GetParametersForImportResponse.add_member(:parameters_valid_to, Shapes::ShapeRef.new(shape: DateType, location_name: "ParametersValidTo"))
    GetParametersForImportResponse.struct_class = Types::GetParametersForImportResponse

    GetPublicKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    GetPublicKeyRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    GetPublicKeyRequest.struct_class = Types::GetPublicKeyRequest

    GetPublicKeyResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GetPublicKeyResponse.add_member(:public_key, Shapes::ShapeRef.new(shape: PublicKeyType, location_name: "PublicKey"))
    GetPublicKeyResponse.add_member(:customer_master_key_spec, Shapes::ShapeRef.new(shape: CustomerMasterKeySpec, deprecated: true, location_name: "CustomerMasterKeySpec", metadata: {"deprecatedMessage"=>"This field has been deprecated. Instead, use the KeySpec field."}))
    GetPublicKeyResponse.add_member(:key_spec, Shapes::ShapeRef.new(shape: KeySpec, location_name: "KeySpec"))
    GetPublicKeyResponse.add_member(:key_usage, Shapes::ShapeRef.new(shape: KeyUsageType, location_name: "KeyUsage"))
    GetPublicKeyResponse.add_member(:encryption_algorithms, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpecList, location_name: "EncryptionAlgorithms"))
    GetPublicKeyResponse.add_member(:signing_algorithms, Shapes::ShapeRef.new(shape: SigningAlgorithmSpecList, location_name: "SigningAlgorithms"))
    GetPublicKeyResponse.struct_class = Types::GetPublicKeyResponse

    GrantConstraints.add_member(:encryption_context_subset, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContextSubset"))
    GrantConstraints.add_member(:encryption_context_equals, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "EncryptionContextEquals"))
    GrantConstraints.struct_class = Types::GrantConstraints

    GrantList.member = Shapes::ShapeRef.new(shape: GrantListEntry)

    GrantListEntry.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    GrantListEntry.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    GrantListEntry.add_member(:name, Shapes::ShapeRef.new(shape: GrantNameType, location_name: "Name"))
    GrantListEntry.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    GrantListEntry.add_member(:grantee_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "GranteePrincipal"))
    GrantListEntry.add_member(:retiring_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "RetiringPrincipal"))
    GrantListEntry.add_member(:issuing_account, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "IssuingAccount"))
    GrantListEntry.add_member(:operations, Shapes::ShapeRef.new(shape: GrantOperationList, location_name: "Operations"))
    GrantListEntry.add_member(:constraints, Shapes::ShapeRef.new(shape: GrantConstraints, location_name: "Constraints"))
    GrantListEntry.struct_class = Types::GrantListEntry

    GrantOperationList.member = Shapes::ShapeRef.new(shape: GrantOperation)

    GrantTokenList.member = Shapes::ShapeRef.new(shape: GrantTokenType)

    ImportKeyMaterialRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ImportKeyMaterialRequest.add_member(:import_token, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "ImportToken"))
    ImportKeyMaterialRequest.add_member(:encrypted_key_material, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "EncryptedKeyMaterial"))
    ImportKeyMaterialRequest.add_member(:valid_to, Shapes::ShapeRef.new(shape: DateType, location_name: "ValidTo"))
    ImportKeyMaterialRequest.add_member(:expiration_model, Shapes::ShapeRef.new(shape: ExpirationModelType, location_name: "ExpirationModel"))
    ImportKeyMaterialRequest.struct_class = Types::ImportKeyMaterialRequest

    ImportKeyMaterialResponse.struct_class = Types::ImportKeyMaterialResponse

    IncorrectKeyException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    IncorrectKeyException.struct_class = Types::IncorrectKeyException

    IncorrectKeyMaterialException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    IncorrectKeyMaterialException.struct_class = Types::IncorrectKeyMaterialException

    IncorrectTrustAnchorException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    IncorrectTrustAnchorException.struct_class = Types::IncorrectTrustAnchorException

    InvalidAliasNameException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidAliasNameException.struct_class = Types::InvalidAliasNameException

    InvalidArnException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidArnException.struct_class = Types::InvalidArnException

    InvalidCiphertextException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidCiphertextException.struct_class = Types::InvalidCiphertextException

    InvalidGrantIdException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidGrantIdException.struct_class = Types::InvalidGrantIdException

    InvalidGrantTokenException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidGrantTokenException.struct_class = Types::InvalidGrantTokenException

    InvalidImportTokenException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidImportTokenException.struct_class = Types::InvalidImportTokenException

    InvalidKeyUsageException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidKeyUsageException.struct_class = Types::InvalidKeyUsageException

    InvalidMarkerException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    InvalidMarkerException.struct_class = Types::InvalidMarkerException

    KMSInternalException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KMSInternalException.struct_class = Types::KMSInternalException

    KMSInvalidMacException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KMSInvalidMacException.struct_class = Types::KMSInvalidMacException

    KMSInvalidSignatureException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KMSInvalidSignatureException.struct_class = Types::KMSInvalidSignatureException

    KMSInvalidStateException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KMSInvalidStateException.struct_class = Types::KMSInvalidStateException

    KeyList.member = Shapes::ShapeRef.new(shape: KeyListEntry)

    KeyListEntry.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    KeyListEntry.add_member(:key_arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "KeyArn"))
    KeyListEntry.struct_class = Types::KeyListEntry

    KeyMetadata.add_member(:aws_account_id, Shapes::ShapeRef.new(shape: AWSAccountIdType, location_name: "AWSAccountId"))
    KeyMetadata.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    KeyMetadata.add_member(:arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "Arn"))
    KeyMetadata.add_member(:creation_date, Shapes::ShapeRef.new(shape: DateType, location_name: "CreationDate"))
    KeyMetadata.add_member(:enabled, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Enabled"))
    KeyMetadata.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, location_name: "Description"))
    KeyMetadata.add_member(:key_usage, Shapes::ShapeRef.new(shape: KeyUsageType, location_name: "KeyUsage"))
    KeyMetadata.add_member(:key_state, Shapes::ShapeRef.new(shape: KeyState, location_name: "KeyState"))
    KeyMetadata.add_member(:deletion_date, Shapes::ShapeRef.new(shape: DateType, location_name: "DeletionDate"))
    KeyMetadata.add_member(:valid_to, Shapes::ShapeRef.new(shape: DateType, location_name: "ValidTo"))
    KeyMetadata.add_member(:origin, Shapes::ShapeRef.new(shape: OriginType, location_name: "Origin"))
    KeyMetadata.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, location_name: "CustomKeyStoreId"))
    KeyMetadata.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    KeyMetadata.add_member(:expiration_model, Shapes::ShapeRef.new(shape: ExpirationModelType, location_name: "ExpirationModel"))
    KeyMetadata.add_member(:key_manager, Shapes::ShapeRef.new(shape: KeyManagerType, location_name: "KeyManager"))
    KeyMetadata.add_member(:customer_master_key_spec, Shapes::ShapeRef.new(shape: CustomerMasterKeySpec, deprecated: true, location_name: "CustomerMasterKeySpec", metadata: {"deprecatedMessage"=>"This field has been deprecated. Instead, use the KeySpec field."}))
    KeyMetadata.add_member(:key_spec, Shapes::ShapeRef.new(shape: KeySpec, location_name: "KeySpec"))
    KeyMetadata.add_member(:encryption_algorithms, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpecList, location_name: "EncryptionAlgorithms"))
    KeyMetadata.add_member(:signing_algorithms, Shapes::ShapeRef.new(shape: SigningAlgorithmSpecList, location_name: "SigningAlgorithms"))
    KeyMetadata.add_member(:multi_region, Shapes::ShapeRef.new(shape: NullableBooleanType, location_name: "MultiRegion"))
    KeyMetadata.add_member(:multi_region_configuration, Shapes::ShapeRef.new(shape: MultiRegionConfiguration, location_name: "MultiRegionConfiguration"))
    KeyMetadata.add_member(:pending_deletion_window_in_days, Shapes::ShapeRef.new(shape: PendingWindowInDaysType, location_name: "PendingDeletionWindowInDays"))
    KeyMetadata.add_member(:mac_algorithms, Shapes::ShapeRef.new(shape: MacAlgorithmSpecList, location_name: "MacAlgorithms"))
    KeyMetadata.add_member(:xks_key_configuration, Shapes::ShapeRef.new(shape: XksKeyConfigurationType, location_name: "XksKeyConfiguration"))
    KeyMetadata.struct_class = Types::KeyMetadata

    KeyUnavailableException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    KeyUnavailableException.struct_class = Types::KeyUnavailableException

    LimitExceededException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    LimitExceededException.struct_class = Types::LimitExceededException

    ListAliasesRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    ListAliasesRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListAliasesRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListAliasesRequest.struct_class = Types::ListAliasesRequest

    ListAliasesResponse.add_member(:aliases, Shapes::ShapeRef.new(shape: AliasList, location_name: "Aliases"))
    ListAliasesResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListAliasesResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListAliasesResponse.struct_class = Types::ListAliasesResponse

    ListGrantsRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListGrantsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListGrantsRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ListGrantsRequest.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    ListGrantsRequest.add_member(:grantee_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, location_name: "GranteePrincipal"))
    ListGrantsRequest.struct_class = Types::ListGrantsRequest

    ListGrantsResponse.add_member(:grants, Shapes::ShapeRef.new(shape: GrantList, location_name: "Grants"))
    ListGrantsResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListGrantsResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListGrantsResponse.struct_class = Types::ListGrantsResponse

    ListKeyPoliciesRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ListKeyPoliciesRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListKeyPoliciesRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListKeyPoliciesRequest.struct_class = Types::ListKeyPoliciesRequest

    ListKeyPoliciesResponse.add_member(:policy_names, Shapes::ShapeRef.new(shape: PolicyNameList, location_name: "PolicyNames"))
    ListKeyPoliciesResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListKeyPoliciesResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListKeyPoliciesResponse.struct_class = Types::ListKeyPoliciesResponse

    ListKeysRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListKeysRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListKeysRequest.struct_class = Types::ListKeysRequest

    ListKeysResponse.add_member(:keys, Shapes::ShapeRef.new(shape: KeyList, location_name: "Keys"))
    ListKeysResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListKeysResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListKeysResponse.struct_class = Types::ListKeysResponse

    ListResourceTagsRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ListResourceTagsRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListResourceTagsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListResourceTagsRequest.struct_class = Types::ListResourceTagsRequest

    ListResourceTagsResponse.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    ListResourceTagsResponse.add_member(:next_marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "NextMarker"))
    ListResourceTagsResponse.add_member(:truncated, Shapes::ShapeRef.new(shape: BooleanType, location_name: "Truncated"))
    ListResourceTagsResponse.struct_class = Types::ListResourceTagsResponse

    ListRetirableGrantsRequest.add_member(:limit, Shapes::ShapeRef.new(shape: LimitType, location_name: "Limit"))
    ListRetirableGrantsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: MarkerType, location_name: "Marker"))
    ListRetirableGrantsRequest.add_member(:retiring_principal, Shapes::ShapeRef.new(shape: PrincipalIdType, required: true, location_name: "RetiringPrincipal"))
    ListRetirableGrantsRequest.struct_class = Types::ListRetirableGrantsRequest

    MacAlgorithmSpecList.member = Shapes::ShapeRef.new(shape: MacAlgorithmSpec)

    MalformedPolicyDocumentException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    MalformedPolicyDocumentException.struct_class = Types::MalformedPolicyDocumentException

    MultiRegionConfiguration.add_member(:multi_region_key_type, Shapes::ShapeRef.new(shape: MultiRegionKeyType, location_name: "MultiRegionKeyType"))
    MultiRegionConfiguration.add_member(:primary_key, Shapes::ShapeRef.new(shape: MultiRegionKey, location_name: "PrimaryKey"))
    MultiRegionConfiguration.add_member(:replica_keys, Shapes::ShapeRef.new(shape: MultiRegionKeyList, location_name: "ReplicaKeys"))
    MultiRegionConfiguration.struct_class = Types::MultiRegionConfiguration

    MultiRegionKey.add_member(:arn, Shapes::ShapeRef.new(shape: ArnType, location_name: "Arn"))
    MultiRegionKey.add_member(:region, Shapes::ShapeRef.new(shape: RegionType, location_name: "Region"))
    MultiRegionKey.struct_class = Types::MultiRegionKey

    MultiRegionKeyList.member = Shapes::ShapeRef.new(shape: MultiRegionKey)

    NotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    NotFoundException.struct_class = Types::NotFoundException

    PolicyNameList.member = Shapes::ShapeRef.new(shape: PolicyNameType)

    PutKeyPolicyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    PutKeyPolicyRequest.add_member(:policy_name, Shapes::ShapeRef.new(shape: PolicyNameType, required: true, location_name: "PolicyName"))
    PutKeyPolicyRequest.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, required: true, location_name: "Policy"))
    PutKeyPolicyRequest.add_member(:bypass_policy_lockout_safety_check, Shapes::ShapeRef.new(shape: BooleanType, location_name: "BypassPolicyLockoutSafetyCheck"))
    PutKeyPolicyRequest.struct_class = Types::PutKeyPolicyRequest

    ReEncryptRequest.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "CiphertextBlob"))
    ReEncryptRequest.add_member(:source_encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "SourceEncryptionContext"))
    ReEncryptRequest.add_member(:source_key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "SourceKeyId"))
    ReEncryptRequest.add_member(:destination_key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "DestinationKeyId"))
    ReEncryptRequest.add_member(:destination_encryption_context, Shapes::ShapeRef.new(shape: EncryptionContextType, location_name: "DestinationEncryptionContext"))
    ReEncryptRequest.add_member(:source_encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "SourceEncryptionAlgorithm"))
    ReEncryptRequest.add_member(:destination_encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "DestinationEncryptionAlgorithm"))
    ReEncryptRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    ReEncryptRequest.struct_class = Types::ReEncryptRequest

    ReEncryptResponse.add_member(:ciphertext_blob, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "CiphertextBlob"))
    ReEncryptResponse.add_member(:source_key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "SourceKeyId"))
    ReEncryptResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    ReEncryptResponse.add_member(:source_encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "SourceEncryptionAlgorithm"))
    ReEncryptResponse.add_member(:destination_encryption_algorithm, Shapes::ShapeRef.new(shape: EncryptionAlgorithmSpec, location_name: "DestinationEncryptionAlgorithm"))
    ReEncryptResponse.struct_class = Types::ReEncryptResponse

    RecipientInfo.add_member(:key_encryption_algorithm, Shapes::ShapeRef.new(shape: KeyEncryptionMechanism, location_name: "KeyEncryptionAlgorithm"))
    RecipientInfo.add_member(:attestation_document, Shapes::ShapeRef.new(shape: AttestationDocumentType, location_name: "AttestationDocument"))
    RecipientInfo.struct_class = Types::RecipientInfo

    ReplicateKeyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ReplicateKeyRequest.add_member(:replica_region, Shapes::ShapeRef.new(shape: RegionType, required: true, location_name: "ReplicaRegion"))
    ReplicateKeyRequest.add_member(:policy, Shapes::ShapeRef.new(shape: PolicyType, location_name: "Policy"))
    ReplicateKeyRequest.add_member(:bypass_policy_lockout_safety_check, Shapes::ShapeRef.new(shape: BooleanType, location_name: "BypassPolicyLockoutSafetyCheck"))
    ReplicateKeyRequest.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, location_name: "Description"))
    ReplicateKeyRequest.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, location_name: "Tags"))
    ReplicateKeyRequest.struct_class = Types::ReplicateKeyRequest

    ReplicateKeyResponse.add_member(:replica_key_metadata, Shapes::ShapeRef.new(shape: KeyMetadata, location_name: "ReplicaKeyMetadata"))
    ReplicateKeyResponse.add_member(:replica_policy, Shapes::ShapeRef.new(shape: PolicyType, location_name: "ReplicaPolicy"))
    ReplicateKeyResponse.add_member(:replica_tags, Shapes::ShapeRef.new(shape: TagList, location_name: "ReplicaTags"))
    ReplicateKeyResponse.struct_class = Types::ReplicateKeyResponse

    RetireGrantRequest.add_member(:grant_token, Shapes::ShapeRef.new(shape: GrantTokenType, location_name: "GrantToken"))
    RetireGrantRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    RetireGrantRequest.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, location_name: "GrantId"))
    RetireGrantRequest.struct_class = Types::RetireGrantRequest

    RevokeGrantRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    RevokeGrantRequest.add_member(:grant_id, Shapes::ShapeRef.new(shape: GrantIdType, required: true, location_name: "GrantId"))
    RevokeGrantRequest.struct_class = Types::RevokeGrantRequest

    ScheduleKeyDeletionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    ScheduleKeyDeletionRequest.add_member(:pending_window_in_days, Shapes::ShapeRef.new(shape: PendingWindowInDaysType, location_name: "PendingWindowInDays"))
    ScheduleKeyDeletionRequest.struct_class = Types::ScheduleKeyDeletionRequest

    ScheduleKeyDeletionResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    ScheduleKeyDeletionResponse.add_member(:deletion_date, Shapes::ShapeRef.new(shape: DateType, location_name: "DeletionDate"))
    ScheduleKeyDeletionResponse.add_member(:key_state, Shapes::ShapeRef.new(shape: KeyState, location_name: "KeyState"))
    ScheduleKeyDeletionResponse.add_member(:pending_window_in_days, Shapes::ShapeRef.new(shape: PendingWindowInDaysType, location_name: "PendingWindowInDays"))
    ScheduleKeyDeletionResponse.struct_class = Types::ScheduleKeyDeletionResponse

    SignRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    SignRequest.add_member(:message, Shapes::ShapeRef.new(shape: PlaintextType, required: true, location_name: "Message"))
    SignRequest.add_member(:message_type, Shapes::ShapeRef.new(shape: MessageType, location_name: "MessageType"))
    SignRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    SignRequest.add_member(:signing_algorithm, Shapes::ShapeRef.new(shape: SigningAlgorithmSpec, required: true, location_name: "SigningAlgorithm"))
    SignRequest.struct_class = Types::SignRequest

    SignResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    SignResponse.add_member(:signature, Shapes::ShapeRef.new(shape: CiphertextType, location_name: "Signature"))
    SignResponse.add_member(:signing_algorithm, Shapes::ShapeRef.new(shape: SigningAlgorithmSpec, location_name: "SigningAlgorithm"))
    SignResponse.struct_class = Types::SignResponse

    SigningAlgorithmSpecList.member = Shapes::ShapeRef.new(shape: SigningAlgorithmSpec)

    Tag.add_member(:tag_key, Shapes::ShapeRef.new(shape: TagKeyType, required: true, location_name: "TagKey"))
    Tag.add_member(:tag_value, Shapes::ShapeRef.new(shape: TagValueType, required: true, location_name: "TagValue"))
    Tag.struct_class = Types::Tag

    TagException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    TagException.struct_class = Types::TagException

    TagKeyList.member = Shapes::ShapeRef.new(shape: TagKeyType)

    TagList.member = Shapes::ShapeRef.new(shape: Tag)

    TagResourceRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    TagResourceRequest.add_member(:tags, Shapes::ShapeRef.new(shape: TagList, required: true, location_name: "Tags"))
    TagResourceRequest.struct_class = Types::TagResourceRequest

    UnsupportedOperationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    UnsupportedOperationException.struct_class = Types::UnsupportedOperationException

    UntagResourceRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    UntagResourceRequest.add_member(:tag_keys, Shapes::ShapeRef.new(shape: TagKeyList, required: true, location_name: "TagKeys"))
    UntagResourceRequest.struct_class = Types::UntagResourceRequest

    UpdateAliasRequest.add_member(:alias_name, Shapes::ShapeRef.new(shape: AliasNameType, required: true, location_name: "AliasName"))
    UpdateAliasRequest.add_member(:target_key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "TargetKeyId"))
    UpdateAliasRequest.struct_class = Types::UpdateAliasRequest

    UpdateCustomKeyStoreRequest.add_member(:custom_key_store_id, Shapes::ShapeRef.new(shape: CustomKeyStoreIdType, required: true, location_name: "CustomKeyStoreId"))
    UpdateCustomKeyStoreRequest.add_member(:new_custom_key_store_name, Shapes::ShapeRef.new(shape: CustomKeyStoreNameType, location_name: "NewCustomKeyStoreName"))
    UpdateCustomKeyStoreRequest.add_member(:key_store_password, Shapes::ShapeRef.new(shape: KeyStorePasswordType, location_name: "KeyStorePassword"))
    UpdateCustomKeyStoreRequest.add_member(:cloud_hsm_cluster_id, Shapes::ShapeRef.new(shape: CloudHsmClusterIdType, location_name: "CloudHsmClusterId"))
    UpdateCustomKeyStoreRequest.add_member(:xks_proxy_uri_endpoint, Shapes::ShapeRef.new(shape: XksProxyUriEndpointType, location_name: "XksProxyUriEndpoint"))
    UpdateCustomKeyStoreRequest.add_member(:xks_proxy_uri_path, Shapes::ShapeRef.new(shape: XksProxyUriPathType, location_name: "XksProxyUriPath"))
    UpdateCustomKeyStoreRequest.add_member(:xks_proxy_vpc_endpoint_service_name, Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceNameType, location_name: "XksProxyVpcEndpointServiceName"))
    UpdateCustomKeyStoreRequest.add_member(:xks_proxy_authentication_credential, Shapes::ShapeRef.new(shape: XksProxyAuthenticationCredentialType, location_name: "XksProxyAuthenticationCredential"))
    UpdateCustomKeyStoreRequest.add_member(:xks_proxy_connectivity, Shapes::ShapeRef.new(shape: XksProxyConnectivityType, location_name: "XksProxyConnectivity"))
    UpdateCustomKeyStoreRequest.struct_class = Types::UpdateCustomKeyStoreRequest

    UpdateCustomKeyStoreResponse.struct_class = Types::UpdateCustomKeyStoreResponse

    UpdateKeyDescriptionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    UpdateKeyDescriptionRequest.add_member(:description, Shapes::ShapeRef.new(shape: DescriptionType, required: true, location_name: "Description"))
    UpdateKeyDescriptionRequest.struct_class = Types::UpdateKeyDescriptionRequest

    UpdatePrimaryRegionRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    UpdatePrimaryRegionRequest.add_member(:primary_region, Shapes::ShapeRef.new(shape: RegionType, required: true, location_name: "PrimaryRegion"))
    UpdatePrimaryRegionRequest.struct_class = Types::UpdatePrimaryRegionRequest

    VerifyMacRequest.add_member(:message, Shapes::ShapeRef.new(shape: PlaintextType, required: true, location_name: "Message"))
    VerifyMacRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    VerifyMacRequest.add_member(:mac_algorithm, Shapes::ShapeRef.new(shape: MacAlgorithmSpec, required: true, location_name: "MacAlgorithm"))
    VerifyMacRequest.add_member(:mac, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "Mac"))
    VerifyMacRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    VerifyMacRequest.struct_class = Types::VerifyMacRequest

    VerifyMacResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    VerifyMacResponse.add_member(:mac_valid, Shapes::ShapeRef.new(shape: BooleanType, location_name: "MacValid"))
    VerifyMacResponse.add_member(:mac_algorithm, Shapes::ShapeRef.new(shape: MacAlgorithmSpec, location_name: "MacAlgorithm"))
    VerifyMacResponse.struct_class = Types::VerifyMacResponse

    VerifyRequest.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, required: true, location_name: "KeyId"))
    VerifyRequest.add_member(:message, Shapes::ShapeRef.new(shape: PlaintextType, required: true, location_name: "Message"))
    VerifyRequest.add_member(:message_type, Shapes::ShapeRef.new(shape: MessageType, location_name: "MessageType"))
    VerifyRequest.add_member(:signature, Shapes::ShapeRef.new(shape: CiphertextType, required: true, location_name: "Signature"))
    VerifyRequest.add_member(:signing_algorithm, Shapes::ShapeRef.new(shape: SigningAlgorithmSpec, required: true, location_name: "SigningAlgorithm"))
    VerifyRequest.add_member(:grant_tokens, Shapes::ShapeRef.new(shape: GrantTokenList, location_name: "GrantTokens"))
    VerifyRequest.struct_class = Types::VerifyRequest

    VerifyResponse.add_member(:key_id, Shapes::ShapeRef.new(shape: KeyIdType, location_name: "KeyId"))
    VerifyResponse.add_member(:signature_valid, Shapes::ShapeRef.new(shape: BooleanType, location_name: "SignatureValid"))
    VerifyResponse.add_member(:signing_algorithm, Shapes::ShapeRef.new(shape: SigningAlgorithmSpec, location_name: "SigningAlgorithm"))
    VerifyResponse.struct_class = Types::VerifyResponse

    XksKeyAlreadyInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksKeyAlreadyInUseException.struct_class = Types::XksKeyAlreadyInUseException

    XksKeyConfigurationType.add_member(:id, Shapes::ShapeRef.new(shape: XksKeyIdType, location_name: "Id"))
    XksKeyConfigurationType.struct_class = Types::XksKeyConfigurationType

    XksKeyInvalidConfigurationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksKeyInvalidConfigurationException.struct_class = Types::XksKeyInvalidConfigurationException

    XksKeyNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksKeyNotFoundException.struct_class = Types::XksKeyNotFoundException

    XksProxyAuthenticationCredentialType.add_member(:access_key_id, Shapes::ShapeRef.new(shape: XksProxyAuthenticationAccessKeyIdType, required: true, location_name: "AccessKeyId"))
    XksProxyAuthenticationCredentialType.add_member(:raw_secret_access_key, Shapes::ShapeRef.new(shape: XksProxyAuthenticationRawSecretAccessKeyType, required: true, location_name: "RawSecretAccessKey"))
    XksProxyAuthenticationCredentialType.struct_class = Types::XksProxyAuthenticationCredentialType

    XksProxyConfigurationType.add_member(:connectivity, Shapes::ShapeRef.new(shape: XksProxyConnectivityType, location_name: "Connectivity"))
    XksProxyConfigurationType.add_member(:access_key_id, Shapes::ShapeRef.new(shape: XksProxyAuthenticationAccessKeyIdType, location_name: "AccessKeyId"))
    XksProxyConfigurationType.add_member(:uri_endpoint, Shapes::ShapeRef.new(shape: XksProxyUriEndpointType, location_name: "UriEndpoint"))
    XksProxyConfigurationType.add_member(:uri_path, Shapes::ShapeRef.new(shape: XksProxyUriPathType, location_name: "UriPath"))
    XksProxyConfigurationType.add_member(:vpc_endpoint_service_name, Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceNameType, location_name: "VpcEndpointServiceName"))
    XksProxyConfigurationType.struct_class = Types::XksProxyConfigurationType

    XksProxyIncorrectAuthenticationCredentialException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyIncorrectAuthenticationCredentialException.struct_class = Types::XksProxyIncorrectAuthenticationCredentialException

    XksProxyInvalidConfigurationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyInvalidConfigurationException.struct_class = Types::XksProxyInvalidConfigurationException

    XksProxyInvalidResponseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyInvalidResponseException.struct_class = Types::XksProxyInvalidResponseException

    XksProxyUriEndpointInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyUriEndpointInUseException.struct_class = Types::XksProxyUriEndpointInUseException

    XksProxyUriInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyUriInUseException.struct_class = Types::XksProxyUriInUseException

    XksProxyUriUnreachableException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyUriUnreachableException.struct_class = Types::XksProxyUriUnreachableException

    XksProxyVpcEndpointServiceInUseException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyVpcEndpointServiceInUseException.struct_class = Types::XksProxyVpcEndpointServiceInUseException

    XksProxyVpcEndpointServiceInvalidConfigurationException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyVpcEndpointServiceInvalidConfigurationException.struct_class = Types::XksProxyVpcEndpointServiceInvalidConfigurationException

    XksProxyVpcEndpointServiceNotFoundException.add_member(:message, Shapes::ShapeRef.new(shape: ErrorMessageType, location_name: "message"))
    XksProxyVpcEndpointServiceNotFoundException.struct_class = Types::XksProxyVpcEndpointServiceNotFoundException


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2014-11-01"

      api.metadata = {
        "apiVersion" => "2014-11-01",
        "endpointPrefix" => "kms",
        "jsonVersion" => "1.1",
        "protocol" => "json",
        "serviceAbbreviation" => "KMS",
        "serviceFullName" => "AWS Key Management Service",
        "serviceId" => "KMS",
        "signatureVersion" => "v4",
        "targetPrefix" => "TrentService",
        "uid" => "kms-2014-11-01",
      }

      api.add_operation(:cancel_key_deletion, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CancelKeyDeletion"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CancelKeyDeletionRequest)
        o.output = Shapes::ShapeRef.new(shape: CancelKeyDeletionResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:connect_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ConnectCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ConnectCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: ConnectCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotActiveException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
      end)

      api.add_operation(:create_alias, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateAlias"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateAliasRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: AlreadyExistsException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidAliasNameException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:create_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInUseException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNameInUseException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotActiveException)
        o.errors << Shapes::ShapeRef.new(shape: IncorrectTrustAnchorException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyUriInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyUriEndpointInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyUriUnreachableException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyIncorrectAuthenticationCredentialException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceInvalidConfigurationException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyInvalidResponseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyInvalidConfigurationException)
      end)

      api.add_operation(:create_grant, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateGrant"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateGrantRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateGrantResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:create_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
        o.errors << Shapes::ShapeRef.new(shape: XksKeyInvalidConfigurationException)
        o.errors << Shapes::ShapeRef.new(shape: XksKeyAlreadyInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksKeyNotFoundException)
      end)

      api.add_operation(:decrypt, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Decrypt"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DecryptRequest)
        o.output = Shapes::ShapeRef.new(shape: DecryptResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidCiphertextException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: IncorrectKeyException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:delete_alias, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteAlias"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteAliasRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:delete_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: DeleteCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreHasCMKsException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:delete_imported_key_material, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteImportedKeyMaterial"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteImportedKeyMaterialRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:describe_custom_key_stores, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DescribeCustomKeyStores"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DescribeCustomKeyStoresRequest)
        o.output = Shapes::ShapeRef.new(shape: DescribeCustomKeyStoresResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:describe_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DescribeKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DescribeKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: DescribeKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:disable_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DisableKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DisableKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:disable_key_rotation, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DisableKeyRotation"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DisableKeyRotationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:disconnect_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DisconnectCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DisconnectCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: DisconnectCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
      end)

      api.add_operation(:enable_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "EnableKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: EnableKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:enable_key_rotation, Seahorse::Model::Operation.new.tap do |o|
        o.name = "EnableKeyRotation"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: EnableKeyRotationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:encrypt, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Encrypt"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: EncryptRequest)
        o.output = Shapes::ShapeRef.new(shape: EncryptResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_data_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateDataKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateDataKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateDataKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_data_key_pair, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateDataKeyPair"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateDataKeyPairRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateDataKeyPairResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:generate_data_key_pair_without_plaintext, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateDataKeyPairWithoutPlaintext"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateDataKeyPairWithoutPlaintextRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateDataKeyPairWithoutPlaintextResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:generate_data_key_without_plaintext, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateDataKeyWithoutPlaintext"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateDataKeyWithoutPlaintextRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateDataKeyWithoutPlaintextResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_mac, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateMac"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateMacRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateMacResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:generate_random, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GenerateRandom"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GenerateRandomRequest)
        o.output = Shapes::ShapeRef.new(shape: GenerateRandomResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
      end)

      api.add_operation(:get_key_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetKeyPolicy"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetKeyPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: GetKeyPolicyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:get_key_rotation_status, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetKeyRotationStatus"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetKeyRotationStatusRequest)
        o.output = Shapes::ShapeRef.new(shape: GetKeyRotationStatusResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:get_parameters_for_import, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetParametersForImport"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetParametersForImportRequest)
        o.output = Shapes::ShapeRef.new(shape: GetParametersForImportResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:get_public_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetPublicKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: GetPublicKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: GetPublicKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:import_key_material, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ImportKeyMaterial"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ImportKeyMaterialRequest)
        o.output = Shapes::ShapeRef.new(shape: ImportKeyMaterialResponse)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidCiphertextException)
        o.errors << Shapes::ShapeRef.new(shape: IncorrectKeyMaterialException)
        o.errors << Shapes::ShapeRef.new(shape: ExpiredImportTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidImportTokenException)
      end)

      api.add_operation(:list_aliases, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListAliases"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListAliasesRequest)
        o.output = Shapes::ShapeRef.new(shape: ListAliasesResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_grants, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListGrants"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListGrantsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListGrantsResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantIdException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_key_policies, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListKeyPolicies"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListKeyPoliciesRequest)
        o.output = Shapes::ShapeRef.new(shape: ListKeyPoliciesResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_keys, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListKeys"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListKeysRequest)
        o.output = Shapes::ShapeRef.new(shape: ListKeysResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_resource_tags, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListResourceTags"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListResourceTagsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListResourceTagsResponse)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:list_retirable_grants, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListRetirableGrants"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListRetirableGrantsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListGrantsResponse)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidMarkerException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o[:pager] = Aws::Pager.new(
          limit_key: "limit",
          tokens: {
            "next_marker" => "marker"
          }
        )
      end)

      api.add_operation(:put_key_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutKeyPolicy"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: PutKeyPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:re_encrypt, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ReEncrypt"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ReEncryptRequest)
        o.output = Shapes::ShapeRef.new(shape: ReEncryptResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidCiphertextException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: IncorrectKeyException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:replicate_key, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ReplicateKey"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ReplicateKeyRequest)
        o.output = Shapes::ShapeRef.new(shape: ReplicateKeyResponse)
        o.errors << Shapes::ShapeRef.new(shape: AlreadyExistsException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: MalformedPolicyDocumentException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:retire_grant, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RetireGrant"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: RetireGrantRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantIdException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:revoke_grant, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RevokeGrant"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: RevokeGrantRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantIdException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:schedule_key_deletion, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ScheduleKeyDeletion"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ScheduleKeyDeletionRequest)
        o.output = Shapes::ShapeRef.new(shape: ScheduleKeyDeletionResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:sign, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Sign"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: SignRequest)
        o.output = Shapes::ShapeRef.new(shape: SignResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:tag_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "TagResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: TagResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
      end)

      api.add_operation(:untag_resource, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UntagResource"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UntagResourceRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: TagException)
      end)

      api.add_operation(:update_alias, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdateAlias"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdateAliasRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: LimitExceededException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:update_custom_key_store, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdateCustomKeyStore"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdateCustomKeyStoreRequest)
        o.output = Shapes::ShapeRef.new(shape: UpdateCustomKeyStoreResponse)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreNameInUseException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotRelatedException)
        o.errors << Shapes::ShapeRef.new(shape: CustomKeyStoreInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterNotActiveException)
        o.errors << Shapes::ShapeRef.new(shape: CloudHsmClusterInvalidConfigurationException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyUriInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyUriEndpointInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyUriUnreachableException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyIncorrectAuthenticationCredentialException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceInUseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceNotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyVpcEndpointServiceInvalidConfigurationException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyInvalidResponseException)
        o.errors << Shapes::ShapeRef.new(shape: XksProxyInvalidConfigurationException)
      end)

      api.add_operation(:update_key_description, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdateKeyDescription"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdateKeyDescriptionRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)

      api.add_operation(:update_primary_region, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UpdatePrimaryRegion"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: UpdatePrimaryRegionRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidArnException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: UnsupportedOperationException)
      end)

      api.add_operation(:verify, Seahorse::Model::Operation.new.tap do |o|
        o.name = "Verify"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: VerifyRequest)
        o.output = Shapes::ShapeRef.new(shape: VerifyResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: DependencyTimeoutException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidSignatureException)
      end)

      api.add_operation(:verify_mac, Seahorse::Model::Operation.new.tap do |o|
        o.name = "VerifyMac"
        o.http_method = "POST"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: VerifyMacRequest)
        o.output = Shapes::ShapeRef.new(shape: VerifyMacResponse)
        o.errors << Shapes::ShapeRef.new(shape: NotFoundException)
        o.errors << Shapes::ShapeRef.new(shape: DisabledException)
        o.errors << Shapes::ShapeRef.new(shape: KeyUnavailableException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidKeyUsageException)
        o.errors << Shapes::ShapeRef.new(shape: InvalidGrantTokenException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInternalException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidMacException)
        o.errors << Shapes::ShapeRef.new(shape: KMSInvalidStateException)
      end)
    end

  end
end
