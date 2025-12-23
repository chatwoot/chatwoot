# frozen_string_literal: true

# WARNING ABOUT GENERATED CODE
#
# This file is generated. See the contributing guide for more information:
# https://github.com/aws/aws-sdk-ruby/blob/version-3/CONTRIBUTING.md
#
# WARNING ABOUT GENERATED CODE

module Aws::S3
  # @api private
  module ClientApi

    include Seahorse::Model

    AbortDate = Shapes::TimestampShape.new(name: 'AbortDate')
    AbortIncompleteMultipartUpload = Shapes::StructureShape.new(name: 'AbortIncompleteMultipartUpload')
    AbortMultipartUploadOutput = Shapes::StructureShape.new(name: 'AbortMultipartUploadOutput')
    AbortMultipartUploadRequest = Shapes::StructureShape.new(name: 'AbortMultipartUploadRequest')
    AbortRuleId = Shapes::StringShape.new(name: 'AbortRuleId')
    AccelerateConfiguration = Shapes::StructureShape.new(name: 'AccelerateConfiguration')
    AcceptRanges = Shapes::StringShape.new(name: 'AcceptRanges')
    AccessControlPolicy = Shapes::StructureShape.new(name: 'AccessControlPolicy')
    AccessControlTranslation = Shapes::StructureShape.new(name: 'AccessControlTranslation')
    AccessPointArn = Shapes::StringShape.new(name: 'AccessPointArn')
    AccountId = Shapes::StringShape.new(name: 'AccountId')
    AllowQuotedRecordDelimiter = Shapes::BooleanShape.new(name: 'AllowQuotedRecordDelimiter')
    AllowedHeader = Shapes::StringShape.new(name: 'AllowedHeader')
    AllowedHeaders = Shapes::ListShape.new(name: 'AllowedHeaders', flattened: true)
    AllowedMethod = Shapes::StringShape.new(name: 'AllowedMethod')
    AllowedMethods = Shapes::ListShape.new(name: 'AllowedMethods', flattened: true)
    AllowedOrigin = Shapes::StringShape.new(name: 'AllowedOrigin')
    AllowedOrigins = Shapes::ListShape.new(name: 'AllowedOrigins', flattened: true)
    AnalyticsAndOperator = Shapes::StructureShape.new(name: 'AnalyticsAndOperator')
    AnalyticsConfiguration = Shapes::StructureShape.new(name: 'AnalyticsConfiguration')
    AnalyticsConfigurationList = Shapes::ListShape.new(name: 'AnalyticsConfigurationList', flattened: true)
    AnalyticsExportDestination = Shapes::StructureShape.new(name: 'AnalyticsExportDestination')
    AnalyticsFilter = Shapes::StructureShape.new(name: 'AnalyticsFilter')
    AnalyticsId = Shapes::StringShape.new(name: 'AnalyticsId')
    AnalyticsS3BucketDestination = Shapes::StructureShape.new(name: 'AnalyticsS3BucketDestination')
    AnalyticsS3ExportFileFormat = Shapes::StringShape.new(name: 'AnalyticsS3ExportFileFormat')
    ArchiveStatus = Shapes::StringShape.new(name: 'ArchiveStatus')
    Body = Shapes::BlobShape.new(name: 'Body')
    Bucket = Shapes::StructureShape.new(name: 'Bucket')
    BucketAccelerateStatus = Shapes::StringShape.new(name: 'BucketAccelerateStatus')
    BucketAlreadyExists = Shapes::StructureShape.new(name: 'BucketAlreadyExists')
    BucketAlreadyOwnedByYou = Shapes::StructureShape.new(name: 'BucketAlreadyOwnedByYou')
    BucketCannedACL = Shapes::StringShape.new(name: 'BucketCannedACL')
    BucketKeyEnabled = Shapes::BooleanShape.new(name: 'BucketKeyEnabled')
    BucketLifecycleConfiguration = Shapes::StructureShape.new(name: 'BucketLifecycleConfiguration')
    BucketLocationConstraint = Shapes::StringShape.new(name: 'BucketLocationConstraint')
    BucketLoggingStatus = Shapes::StructureShape.new(name: 'BucketLoggingStatus')
    BucketLogsPermission = Shapes::StringShape.new(name: 'BucketLogsPermission')
    BucketName = Shapes::StringShape.new(name: 'BucketName')
    BucketVersioningStatus = Shapes::StringShape.new(name: 'BucketVersioningStatus')
    Buckets = Shapes::ListShape.new(name: 'Buckets')
    BypassGovernanceRetention = Shapes::BooleanShape.new(name: 'BypassGovernanceRetention')
    BytesProcessed = Shapes::IntegerShape.new(name: 'BytesProcessed')
    BytesReturned = Shapes::IntegerShape.new(name: 'BytesReturned')
    BytesScanned = Shapes::IntegerShape.new(name: 'BytesScanned')
    CORSConfiguration = Shapes::StructureShape.new(name: 'CORSConfiguration')
    CORSRule = Shapes::StructureShape.new(name: 'CORSRule')
    CORSRules = Shapes::ListShape.new(name: 'CORSRules', flattened: true)
    CSVInput = Shapes::StructureShape.new(name: 'CSVInput')
    CSVOutput = Shapes::StructureShape.new(name: 'CSVOutput')
    CacheControl = Shapes::StringShape.new(name: 'CacheControl')
    Checksum = Shapes::StructureShape.new(name: 'Checksum')
    ChecksumAlgorithm = Shapes::StringShape.new(name: 'ChecksumAlgorithm')
    ChecksumAlgorithmList = Shapes::ListShape.new(name: 'ChecksumAlgorithmList', flattened: true)
    ChecksumCRC32 = Shapes::StringShape.new(name: 'ChecksumCRC32')
    ChecksumCRC32C = Shapes::StringShape.new(name: 'ChecksumCRC32C')
    ChecksumMode = Shapes::StringShape.new(name: 'ChecksumMode')
    ChecksumSHA1 = Shapes::StringShape.new(name: 'ChecksumSHA1')
    ChecksumSHA256 = Shapes::StringShape.new(name: 'ChecksumSHA256')
    CloudFunction = Shapes::StringShape.new(name: 'CloudFunction')
    CloudFunctionConfiguration = Shapes::StructureShape.new(name: 'CloudFunctionConfiguration')
    CloudFunctionInvocationRole = Shapes::StringShape.new(name: 'CloudFunctionInvocationRole')
    Code = Shapes::StringShape.new(name: 'Code')
    Comments = Shapes::StringShape.new(name: 'Comments')
    CommonPrefix = Shapes::StructureShape.new(name: 'CommonPrefix')
    CommonPrefixList = Shapes::ListShape.new(name: 'CommonPrefixList', flattened: true)
    CompleteMultipartUploadOutput = Shapes::StructureShape.new(name: 'CompleteMultipartUploadOutput')
    CompleteMultipartUploadRequest = Shapes::StructureShape.new(name: 'CompleteMultipartUploadRequest')
    CompletedMultipartUpload = Shapes::StructureShape.new(name: 'CompletedMultipartUpload')
    CompletedPart = Shapes::StructureShape.new(name: 'CompletedPart')
    CompletedPartList = Shapes::ListShape.new(name: 'CompletedPartList', flattened: true)
    CompressionType = Shapes::StringShape.new(name: 'CompressionType')
    Condition = Shapes::StructureShape.new(name: 'Condition')
    ConfirmRemoveSelfBucketAccess = Shapes::BooleanShape.new(name: 'ConfirmRemoveSelfBucketAccess')
    ContentDisposition = Shapes::StringShape.new(name: 'ContentDisposition')
    ContentEncoding = Shapes::StringShape.new(name: 'ContentEncoding')
    ContentLanguage = Shapes::StringShape.new(name: 'ContentLanguage')
    ContentLength = Shapes::IntegerShape.new(name: 'ContentLength')
    ContentMD5 = Shapes::StringShape.new(name: 'ContentMD5')
    ContentRange = Shapes::StringShape.new(name: 'ContentRange')
    ContentType = Shapes::StringShape.new(name: 'ContentType')
    ContinuationEvent = Shapes::StructureShape.new(name: 'ContinuationEvent')
    CopyObjectOutput = Shapes::StructureShape.new(name: 'CopyObjectOutput')
    CopyObjectRequest = Shapes::StructureShape.new(name: 'CopyObjectRequest')
    CopyObjectResult = Shapes::StructureShape.new(name: 'CopyObjectResult')
    CopyPartResult = Shapes::StructureShape.new(name: 'CopyPartResult')
    CopySource = Shapes::StringShape.new(name: 'CopySource')
    CopySourceIfMatch = Shapes::StringShape.new(name: 'CopySourceIfMatch')
    CopySourceIfModifiedSince = Shapes::TimestampShape.new(name: 'CopySourceIfModifiedSince')
    CopySourceIfNoneMatch = Shapes::StringShape.new(name: 'CopySourceIfNoneMatch')
    CopySourceIfUnmodifiedSince = Shapes::TimestampShape.new(name: 'CopySourceIfUnmodifiedSince')
    CopySourceRange = Shapes::StringShape.new(name: 'CopySourceRange')
    CopySourceSSECustomerAlgorithm = Shapes::StringShape.new(name: 'CopySourceSSECustomerAlgorithm')
    CopySourceSSECustomerKey = Shapes::StringShape.new(name: 'CopySourceSSECustomerKey')
    CopySourceSSECustomerKeyMD5 = Shapes::StringShape.new(name: 'CopySourceSSECustomerKeyMD5')
    CopySourceVersionId = Shapes::StringShape.new(name: 'CopySourceVersionId')
    CreateBucketConfiguration = Shapes::StructureShape.new(name: 'CreateBucketConfiguration')
    CreateBucketOutput = Shapes::StructureShape.new(name: 'CreateBucketOutput')
    CreateBucketRequest = Shapes::StructureShape.new(name: 'CreateBucketRequest')
    CreateMultipartUploadOutput = Shapes::StructureShape.new(name: 'CreateMultipartUploadOutput')
    CreateMultipartUploadRequest = Shapes::StructureShape.new(name: 'CreateMultipartUploadRequest')
    CreationDate = Shapes::TimestampShape.new(name: 'CreationDate')
    Date = Shapes::TimestampShape.new(name: 'Date', timestampFormat: "iso8601")
    Days = Shapes::IntegerShape.new(name: 'Days')
    DaysAfterInitiation = Shapes::IntegerShape.new(name: 'DaysAfterInitiation')
    DefaultRetention = Shapes::StructureShape.new(name: 'DefaultRetention')
    Delete = Shapes::StructureShape.new(name: 'Delete')
    DeleteBucketAnalyticsConfigurationRequest = Shapes::StructureShape.new(name: 'DeleteBucketAnalyticsConfigurationRequest')
    DeleteBucketCorsRequest = Shapes::StructureShape.new(name: 'DeleteBucketCorsRequest')
    DeleteBucketEncryptionRequest = Shapes::StructureShape.new(name: 'DeleteBucketEncryptionRequest')
    DeleteBucketIntelligentTieringConfigurationRequest = Shapes::StructureShape.new(name: 'DeleteBucketIntelligentTieringConfigurationRequest')
    DeleteBucketInventoryConfigurationRequest = Shapes::StructureShape.new(name: 'DeleteBucketInventoryConfigurationRequest')
    DeleteBucketLifecycleRequest = Shapes::StructureShape.new(name: 'DeleteBucketLifecycleRequest')
    DeleteBucketMetricsConfigurationRequest = Shapes::StructureShape.new(name: 'DeleteBucketMetricsConfigurationRequest')
    DeleteBucketOwnershipControlsRequest = Shapes::StructureShape.new(name: 'DeleteBucketOwnershipControlsRequest')
    DeleteBucketPolicyRequest = Shapes::StructureShape.new(name: 'DeleteBucketPolicyRequest')
    DeleteBucketReplicationRequest = Shapes::StructureShape.new(name: 'DeleteBucketReplicationRequest')
    DeleteBucketRequest = Shapes::StructureShape.new(name: 'DeleteBucketRequest')
    DeleteBucketTaggingRequest = Shapes::StructureShape.new(name: 'DeleteBucketTaggingRequest')
    DeleteBucketWebsiteRequest = Shapes::StructureShape.new(name: 'DeleteBucketWebsiteRequest')
    DeleteMarker = Shapes::BooleanShape.new(name: 'DeleteMarker')
    DeleteMarkerEntry = Shapes::StructureShape.new(name: 'DeleteMarkerEntry')
    DeleteMarkerReplication = Shapes::StructureShape.new(name: 'DeleteMarkerReplication')
    DeleteMarkerReplicationStatus = Shapes::StringShape.new(name: 'DeleteMarkerReplicationStatus')
    DeleteMarkerVersionId = Shapes::StringShape.new(name: 'DeleteMarkerVersionId')
    DeleteMarkers = Shapes::ListShape.new(name: 'DeleteMarkers', flattened: true)
    DeleteObjectOutput = Shapes::StructureShape.new(name: 'DeleteObjectOutput')
    DeleteObjectRequest = Shapes::StructureShape.new(name: 'DeleteObjectRequest')
    DeleteObjectTaggingOutput = Shapes::StructureShape.new(name: 'DeleteObjectTaggingOutput')
    DeleteObjectTaggingRequest = Shapes::StructureShape.new(name: 'DeleteObjectTaggingRequest')
    DeleteObjectsOutput = Shapes::StructureShape.new(name: 'DeleteObjectsOutput')
    DeleteObjectsRequest = Shapes::StructureShape.new(name: 'DeleteObjectsRequest')
    DeletePublicAccessBlockRequest = Shapes::StructureShape.new(name: 'DeletePublicAccessBlockRequest')
    DeletedObject = Shapes::StructureShape.new(name: 'DeletedObject')
    DeletedObjects = Shapes::ListShape.new(name: 'DeletedObjects', flattened: true)
    Delimiter = Shapes::StringShape.new(name: 'Delimiter')
    Description = Shapes::StringShape.new(name: 'Description')
    Destination = Shapes::StructureShape.new(name: 'Destination')
    DisplayName = Shapes::StringShape.new(name: 'DisplayName')
    ETag = Shapes::StringShape.new(name: 'ETag')
    EmailAddress = Shapes::StringShape.new(name: 'EmailAddress')
    EnableRequestProgress = Shapes::BooleanShape.new(name: 'EnableRequestProgress')
    EncodingType = Shapes::StringShape.new(name: 'EncodingType')
    Encryption = Shapes::StructureShape.new(name: 'Encryption')
    EncryptionConfiguration = Shapes::StructureShape.new(name: 'EncryptionConfiguration')
    End = Shapes::IntegerShape.new(name: 'End')
    EndEvent = Shapes::StructureShape.new(name: 'EndEvent')
    Error = Shapes::StructureShape.new(name: 'Error')
    ErrorCode = Shapes::StringShape.new(name: 'ErrorCode')
    ErrorDocument = Shapes::StructureShape.new(name: 'ErrorDocument')
    ErrorMessage = Shapes::StringShape.new(name: 'ErrorMessage')
    Errors = Shapes::ListShape.new(name: 'Errors', flattened: true)
    Event = Shapes::StringShape.new(name: 'Event')
    EventBridgeConfiguration = Shapes::StructureShape.new(name: 'EventBridgeConfiguration')
    EventList = Shapes::ListShape.new(name: 'EventList', flattened: true)
    ExistingObjectReplication = Shapes::StructureShape.new(name: 'ExistingObjectReplication')
    ExistingObjectReplicationStatus = Shapes::StringShape.new(name: 'ExistingObjectReplicationStatus')
    Expiration = Shapes::StringShape.new(name: 'Expiration')
    ExpirationStatus = Shapes::StringShape.new(name: 'ExpirationStatus')
    ExpiredObjectDeleteMarker = Shapes::BooleanShape.new(name: 'ExpiredObjectDeleteMarker')
    Expires = Shapes::TimestampShape.new(name: 'Expires')
    ExpiresString = Shapes::StringShape.new(name: 'ExpiresString')
    ExposeHeader = Shapes::StringShape.new(name: 'ExposeHeader')
    ExposeHeaders = Shapes::ListShape.new(name: 'ExposeHeaders', flattened: true)
    Expression = Shapes::StringShape.new(name: 'Expression')
    ExpressionType = Shapes::StringShape.new(name: 'ExpressionType')
    FetchOwner = Shapes::BooleanShape.new(name: 'FetchOwner')
    FieldDelimiter = Shapes::StringShape.new(name: 'FieldDelimiter')
    FileHeaderInfo = Shapes::StringShape.new(name: 'FileHeaderInfo')
    FilterRule = Shapes::StructureShape.new(name: 'FilterRule')
    FilterRuleList = Shapes::ListShape.new(name: 'FilterRuleList', flattened: true)
    FilterRuleName = Shapes::StringShape.new(name: 'FilterRuleName')
    FilterRuleValue = Shapes::StringShape.new(name: 'FilterRuleValue')
    GetBucketAccelerateConfigurationOutput = Shapes::StructureShape.new(name: 'GetBucketAccelerateConfigurationOutput')
    GetBucketAccelerateConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketAccelerateConfigurationRequest')
    GetBucketAclOutput = Shapes::StructureShape.new(name: 'GetBucketAclOutput')
    GetBucketAclRequest = Shapes::StructureShape.new(name: 'GetBucketAclRequest')
    GetBucketAnalyticsConfigurationOutput = Shapes::StructureShape.new(name: 'GetBucketAnalyticsConfigurationOutput')
    GetBucketAnalyticsConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketAnalyticsConfigurationRequest')
    GetBucketCorsOutput = Shapes::StructureShape.new(name: 'GetBucketCorsOutput')
    GetBucketCorsRequest = Shapes::StructureShape.new(name: 'GetBucketCorsRequest')
    GetBucketEncryptionOutput = Shapes::StructureShape.new(name: 'GetBucketEncryptionOutput')
    GetBucketEncryptionRequest = Shapes::StructureShape.new(name: 'GetBucketEncryptionRequest')
    GetBucketIntelligentTieringConfigurationOutput = Shapes::StructureShape.new(name: 'GetBucketIntelligentTieringConfigurationOutput')
    GetBucketIntelligentTieringConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketIntelligentTieringConfigurationRequest')
    GetBucketInventoryConfigurationOutput = Shapes::StructureShape.new(name: 'GetBucketInventoryConfigurationOutput')
    GetBucketInventoryConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketInventoryConfigurationRequest')
    GetBucketLifecycleConfigurationOutput = Shapes::StructureShape.new(name: 'GetBucketLifecycleConfigurationOutput')
    GetBucketLifecycleConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketLifecycleConfigurationRequest')
    GetBucketLifecycleOutput = Shapes::StructureShape.new(name: 'GetBucketLifecycleOutput')
    GetBucketLifecycleRequest = Shapes::StructureShape.new(name: 'GetBucketLifecycleRequest')
    GetBucketLocationOutput = Shapes::StructureShape.new(name: 'GetBucketLocationOutput')
    GetBucketLocationRequest = Shapes::StructureShape.new(name: 'GetBucketLocationRequest')
    GetBucketLoggingOutput = Shapes::StructureShape.new(name: 'GetBucketLoggingOutput')
    GetBucketLoggingRequest = Shapes::StructureShape.new(name: 'GetBucketLoggingRequest')
    GetBucketMetricsConfigurationOutput = Shapes::StructureShape.new(name: 'GetBucketMetricsConfigurationOutput')
    GetBucketMetricsConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketMetricsConfigurationRequest')
    GetBucketNotificationConfigurationRequest = Shapes::StructureShape.new(name: 'GetBucketNotificationConfigurationRequest')
    GetBucketOwnershipControlsOutput = Shapes::StructureShape.new(name: 'GetBucketOwnershipControlsOutput')
    GetBucketOwnershipControlsRequest = Shapes::StructureShape.new(name: 'GetBucketOwnershipControlsRequest')
    GetBucketPolicyOutput = Shapes::StructureShape.new(name: 'GetBucketPolicyOutput')
    GetBucketPolicyRequest = Shapes::StructureShape.new(name: 'GetBucketPolicyRequest')
    GetBucketPolicyStatusOutput = Shapes::StructureShape.new(name: 'GetBucketPolicyStatusOutput')
    GetBucketPolicyStatusRequest = Shapes::StructureShape.new(name: 'GetBucketPolicyStatusRequest')
    GetBucketReplicationOutput = Shapes::StructureShape.new(name: 'GetBucketReplicationOutput')
    GetBucketReplicationRequest = Shapes::StructureShape.new(name: 'GetBucketReplicationRequest')
    GetBucketRequestPaymentOutput = Shapes::StructureShape.new(name: 'GetBucketRequestPaymentOutput')
    GetBucketRequestPaymentRequest = Shapes::StructureShape.new(name: 'GetBucketRequestPaymentRequest')
    GetBucketTaggingOutput = Shapes::StructureShape.new(name: 'GetBucketTaggingOutput')
    GetBucketTaggingRequest = Shapes::StructureShape.new(name: 'GetBucketTaggingRequest')
    GetBucketVersioningOutput = Shapes::StructureShape.new(name: 'GetBucketVersioningOutput')
    GetBucketVersioningRequest = Shapes::StructureShape.new(name: 'GetBucketVersioningRequest')
    GetBucketWebsiteOutput = Shapes::StructureShape.new(name: 'GetBucketWebsiteOutput')
    GetBucketWebsiteRequest = Shapes::StructureShape.new(name: 'GetBucketWebsiteRequest')
    GetObjectAclOutput = Shapes::StructureShape.new(name: 'GetObjectAclOutput')
    GetObjectAclRequest = Shapes::StructureShape.new(name: 'GetObjectAclRequest')
    GetObjectAttributesOutput = Shapes::StructureShape.new(name: 'GetObjectAttributesOutput')
    GetObjectAttributesParts = Shapes::StructureShape.new(name: 'GetObjectAttributesParts')
    GetObjectAttributesRequest = Shapes::StructureShape.new(name: 'GetObjectAttributesRequest')
    GetObjectLegalHoldOutput = Shapes::StructureShape.new(name: 'GetObjectLegalHoldOutput')
    GetObjectLegalHoldRequest = Shapes::StructureShape.new(name: 'GetObjectLegalHoldRequest')
    GetObjectLockConfigurationOutput = Shapes::StructureShape.new(name: 'GetObjectLockConfigurationOutput')
    GetObjectLockConfigurationRequest = Shapes::StructureShape.new(name: 'GetObjectLockConfigurationRequest')
    GetObjectOutput = Shapes::StructureShape.new(name: 'GetObjectOutput')
    GetObjectRequest = Shapes::StructureShape.new(name: 'GetObjectRequest')
    GetObjectResponseStatusCode = Shapes::IntegerShape.new(name: 'GetObjectResponseStatusCode')
    GetObjectRetentionOutput = Shapes::StructureShape.new(name: 'GetObjectRetentionOutput')
    GetObjectRetentionRequest = Shapes::StructureShape.new(name: 'GetObjectRetentionRequest')
    GetObjectTaggingOutput = Shapes::StructureShape.new(name: 'GetObjectTaggingOutput')
    GetObjectTaggingRequest = Shapes::StructureShape.new(name: 'GetObjectTaggingRequest')
    GetObjectTorrentOutput = Shapes::StructureShape.new(name: 'GetObjectTorrentOutput')
    GetObjectTorrentRequest = Shapes::StructureShape.new(name: 'GetObjectTorrentRequest')
    GetPublicAccessBlockOutput = Shapes::StructureShape.new(name: 'GetPublicAccessBlockOutput')
    GetPublicAccessBlockRequest = Shapes::StructureShape.new(name: 'GetPublicAccessBlockRequest')
    GlacierJobParameters = Shapes::StructureShape.new(name: 'GlacierJobParameters')
    Grant = Shapes::StructureShape.new(name: 'Grant')
    GrantFullControl = Shapes::StringShape.new(name: 'GrantFullControl')
    GrantRead = Shapes::StringShape.new(name: 'GrantRead')
    GrantReadACP = Shapes::StringShape.new(name: 'GrantReadACP')
    GrantWrite = Shapes::StringShape.new(name: 'GrantWrite')
    GrantWriteACP = Shapes::StringShape.new(name: 'GrantWriteACP')
    Grantee = Shapes::StructureShape.new(name: 'Grantee', xmlNamespace: {"prefix"=>"xsi", "uri"=>"http://www.w3.org/2001/XMLSchema-instance"})
    Grants = Shapes::ListShape.new(name: 'Grants')
    HeadBucketRequest = Shapes::StructureShape.new(name: 'HeadBucketRequest')
    HeadObjectOutput = Shapes::StructureShape.new(name: 'HeadObjectOutput')
    HeadObjectRequest = Shapes::StructureShape.new(name: 'HeadObjectRequest')
    HostName = Shapes::StringShape.new(name: 'HostName')
    HttpErrorCodeReturnedEquals = Shapes::StringShape.new(name: 'HttpErrorCodeReturnedEquals')
    HttpRedirectCode = Shapes::StringShape.new(name: 'HttpRedirectCode')
    ID = Shapes::StringShape.new(name: 'ID')
    IfMatch = Shapes::StringShape.new(name: 'IfMatch')
    IfModifiedSince = Shapes::TimestampShape.new(name: 'IfModifiedSince')
    IfNoneMatch = Shapes::StringShape.new(name: 'IfNoneMatch')
    IfUnmodifiedSince = Shapes::TimestampShape.new(name: 'IfUnmodifiedSince')
    IndexDocument = Shapes::StructureShape.new(name: 'IndexDocument')
    Initiated = Shapes::TimestampShape.new(name: 'Initiated')
    Initiator = Shapes::StructureShape.new(name: 'Initiator')
    InputSerialization = Shapes::StructureShape.new(name: 'InputSerialization')
    IntelligentTieringAccessTier = Shapes::StringShape.new(name: 'IntelligentTieringAccessTier')
    IntelligentTieringAndOperator = Shapes::StructureShape.new(name: 'IntelligentTieringAndOperator')
    IntelligentTieringConfiguration = Shapes::StructureShape.new(name: 'IntelligentTieringConfiguration')
    IntelligentTieringConfigurationList = Shapes::ListShape.new(name: 'IntelligentTieringConfigurationList', flattened: true)
    IntelligentTieringDays = Shapes::IntegerShape.new(name: 'IntelligentTieringDays')
    IntelligentTieringFilter = Shapes::StructureShape.new(name: 'IntelligentTieringFilter')
    IntelligentTieringId = Shapes::StringShape.new(name: 'IntelligentTieringId')
    IntelligentTieringStatus = Shapes::StringShape.new(name: 'IntelligentTieringStatus')
    InvalidObjectState = Shapes::StructureShape.new(name: 'InvalidObjectState')
    InventoryConfiguration = Shapes::StructureShape.new(name: 'InventoryConfiguration')
    InventoryConfigurationList = Shapes::ListShape.new(name: 'InventoryConfigurationList', flattened: true)
    InventoryDestination = Shapes::StructureShape.new(name: 'InventoryDestination')
    InventoryEncryption = Shapes::StructureShape.new(name: 'InventoryEncryption')
    InventoryFilter = Shapes::StructureShape.new(name: 'InventoryFilter')
    InventoryFormat = Shapes::StringShape.new(name: 'InventoryFormat')
    InventoryFrequency = Shapes::StringShape.new(name: 'InventoryFrequency')
    InventoryId = Shapes::StringShape.new(name: 'InventoryId')
    InventoryIncludedObjectVersions = Shapes::StringShape.new(name: 'InventoryIncludedObjectVersions')
    InventoryOptionalField = Shapes::StringShape.new(name: 'InventoryOptionalField')
    InventoryOptionalFields = Shapes::ListShape.new(name: 'InventoryOptionalFields')
    InventoryS3BucketDestination = Shapes::StructureShape.new(name: 'InventoryS3BucketDestination')
    InventorySchedule = Shapes::StructureShape.new(name: 'InventorySchedule')
    IsEnabled = Shapes::BooleanShape.new(name: 'IsEnabled')
    IsLatest = Shapes::BooleanShape.new(name: 'IsLatest')
    IsPublic = Shapes::BooleanShape.new(name: 'IsPublic')
    IsTruncated = Shapes::BooleanShape.new(name: 'IsTruncated')
    JSONInput = Shapes::StructureShape.new(name: 'JSONInput')
    JSONOutput = Shapes::StructureShape.new(name: 'JSONOutput')
    JSONType = Shapes::StringShape.new(name: 'JSONType')
    KMSContext = Shapes::StringShape.new(name: 'KMSContext')
    KeyCount = Shapes::IntegerShape.new(name: 'KeyCount')
    KeyMarker = Shapes::StringShape.new(name: 'KeyMarker')
    KeyPrefixEquals = Shapes::StringShape.new(name: 'KeyPrefixEquals')
    LambdaFunctionArn = Shapes::StringShape.new(name: 'LambdaFunctionArn')
    LambdaFunctionConfiguration = Shapes::StructureShape.new(name: 'LambdaFunctionConfiguration')
    LambdaFunctionConfigurationList = Shapes::ListShape.new(name: 'LambdaFunctionConfigurationList', flattened: true)
    LastModified = Shapes::TimestampShape.new(name: 'LastModified')
    LifecycleConfiguration = Shapes::StructureShape.new(name: 'LifecycleConfiguration')
    LifecycleExpiration = Shapes::StructureShape.new(name: 'LifecycleExpiration')
    LifecycleRule = Shapes::StructureShape.new(name: 'LifecycleRule')
    LifecycleRuleAndOperator = Shapes::StructureShape.new(name: 'LifecycleRuleAndOperator')
    LifecycleRuleFilter = Shapes::StructureShape.new(name: 'LifecycleRuleFilter')
    LifecycleRules = Shapes::ListShape.new(name: 'LifecycleRules', flattened: true)
    ListBucketAnalyticsConfigurationsOutput = Shapes::StructureShape.new(name: 'ListBucketAnalyticsConfigurationsOutput')
    ListBucketAnalyticsConfigurationsRequest = Shapes::StructureShape.new(name: 'ListBucketAnalyticsConfigurationsRequest')
    ListBucketIntelligentTieringConfigurationsOutput = Shapes::StructureShape.new(name: 'ListBucketIntelligentTieringConfigurationsOutput')
    ListBucketIntelligentTieringConfigurationsRequest = Shapes::StructureShape.new(name: 'ListBucketIntelligentTieringConfigurationsRequest')
    ListBucketInventoryConfigurationsOutput = Shapes::StructureShape.new(name: 'ListBucketInventoryConfigurationsOutput')
    ListBucketInventoryConfigurationsRequest = Shapes::StructureShape.new(name: 'ListBucketInventoryConfigurationsRequest')
    ListBucketMetricsConfigurationsOutput = Shapes::StructureShape.new(name: 'ListBucketMetricsConfigurationsOutput')
    ListBucketMetricsConfigurationsRequest = Shapes::StructureShape.new(name: 'ListBucketMetricsConfigurationsRequest')
    ListBucketsOutput = Shapes::StructureShape.new(name: 'ListBucketsOutput')
    ListMultipartUploadsOutput = Shapes::StructureShape.new(name: 'ListMultipartUploadsOutput')
    ListMultipartUploadsRequest = Shapes::StructureShape.new(name: 'ListMultipartUploadsRequest')
    ListObjectVersionsOutput = Shapes::StructureShape.new(name: 'ListObjectVersionsOutput')
    ListObjectVersionsRequest = Shapes::StructureShape.new(name: 'ListObjectVersionsRequest')
    ListObjectsOutput = Shapes::StructureShape.new(name: 'ListObjectsOutput')
    ListObjectsRequest = Shapes::StructureShape.new(name: 'ListObjectsRequest')
    ListObjectsV2Output = Shapes::StructureShape.new(name: 'ListObjectsV2Output')
    ListObjectsV2Request = Shapes::StructureShape.new(name: 'ListObjectsV2Request')
    ListPartsOutput = Shapes::StructureShape.new(name: 'ListPartsOutput')
    ListPartsRequest = Shapes::StructureShape.new(name: 'ListPartsRequest')
    Location = Shapes::StringShape.new(name: 'Location')
    LocationPrefix = Shapes::StringShape.new(name: 'LocationPrefix')
    LoggingEnabled = Shapes::StructureShape.new(name: 'LoggingEnabled')
    MFA = Shapes::StringShape.new(name: 'MFA')
    MFADelete = Shapes::StringShape.new(name: 'MFADelete')
    MFADeleteStatus = Shapes::StringShape.new(name: 'MFADeleteStatus')
    Marker = Shapes::StringShape.new(name: 'Marker')
    MaxAgeSeconds = Shapes::IntegerShape.new(name: 'MaxAgeSeconds')
    MaxKeys = Shapes::IntegerShape.new(name: 'MaxKeys')
    MaxParts = Shapes::IntegerShape.new(name: 'MaxParts')
    MaxUploads = Shapes::IntegerShape.new(name: 'MaxUploads')
    Message = Shapes::StringShape.new(name: 'Message')
    Metadata = Shapes::MapShape.new(name: 'Metadata')
    MetadataDirective = Shapes::StringShape.new(name: 'MetadataDirective')
    MetadataEntry = Shapes::StructureShape.new(name: 'MetadataEntry')
    MetadataKey = Shapes::StringShape.new(name: 'MetadataKey')
    MetadataValue = Shapes::StringShape.new(name: 'MetadataValue')
    Metrics = Shapes::StructureShape.new(name: 'Metrics')
    MetricsAndOperator = Shapes::StructureShape.new(name: 'MetricsAndOperator')
    MetricsConfiguration = Shapes::StructureShape.new(name: 'MetricsConfiguration')
    MetricsConfigurationList = Shapes::ListShape.new(name: 'MetricsConfigurationList', flattened: true)
    MetricsFilter = Shapes::StructureShape.new(name: 'MetricsFilter')
    MetricsId = Shapes::StringShape.new(name: 'MetricsId')
    MetricsStatus = Shapes::StringShape.new(name: 'MetricsStatus')
    Minutes = Shapes::IntegerShape.new(name: 'Minutes')
    MissingMeta = Shapes::IntegerShape.new(name: 'MissingMeta')
    MultipartUpload = Shapes::StructureShape.new(name: 'MultipartUpload')
    MultipartUploadId = Shapes::StringShape.new(name: 'MultipartUploadId')
    MultipartUploadList = Shapes::ListShape.new(name: 'MultipartUploadList', flattened: true)
    NextKeyMarker = Shapes::StringShape.new(name: 'NextKeyMarker')
    NextMarker = Shapes::StringShape.new(name: 'NextMarker')
    NextPartNumberMarker = Shapes::IntegerShape.new(name: 'NextPartNumberMarker')
    NextToken = Shapes::StringShape.new(name: 'NextToken')
    NextUploadIdMarker = Shapes::StringShape.new(name: 'NextUploadIdMarker')
    NextVersionIdMarker = Shapes::StringShape.new(name: 'NextVersionIdMarker')
    NoSuchBucket = Shapes::StructureShape.new(name: 'NoSuchBucket')
    NoSuchKey = Shapes::StructureShape.new(name: 'NoSuchKey')
    NoSuchUpload = Shapes::StructureShape.new(name: 'NoSuchUpload')
    NoncurrentVersionExpiration = Shapes::StructureShape.new(name: 'NoncurrentVersionExpiration')
    NoncurrentVersionTransition = Shapes::StructureShape.new(name: 'NoncurrentVersionTransition')
    NoncurrentVersionTransitionList = Shapes::ListShape.new(name: 'NoncurrentVersionTransitionList', flattened: true)
    NotificationConfiguration = Shapes::StructureShape.new(name: 'NotificationConfiguration')
    NotificationConfigurationDeprecated = Shapes::StructureShape.new(name: 'NotificationConfigurationDeprecated')
    NotificationConfigurationFilter = Shapes::StructureShape.new(name: 'NotificationConfigurationFilter')
    NotificationId = Shapes::StringShape.new(name: 'NotificationId')
    Object = Shapes::StructureShape.new(name: 'Object')
    ObjectAlreadyInActiveTierError = Shapes::StructureShape.new(name: 'ObjectAlreadyInActiveTierError')
    ObjectAttributes = Shapes::StringShape.new(name: 'ObjectAttributes')
    ObjectAttributesList = Shapes::ListShape.new(name: 'ObjectAttributesList')
    ObjectCannedACL = Shapes::StringShape.new(name: 'ObjectCannedACL')
    ObjectIdentifier = Shapes::StructureShape.new(name: 'ObjectIdentifier')
    ObjectIdentifierList = Shapes::ListShape.new(name: 'ObjectIdentifierList', flattened: true)
    ObjectKey = Shapes::StringShape.new(name: 'ObjectKey')
    ObjectList = Shapes::ListShape.new(name: 'ObjectList', flattened: true)
    ObjectLockConfiguration = Shapes::StructureShape.new(name: 'ObjectLockConfiguration')
    ObjectLockEnabled = Shapes::StringShape.new(name: 'ObjectLockEnabled')
    ObjectLockEnabledForBucket = Shapes::BooleanShape.new(name: 'ObjectLockEnabledForBucket')
    ObjectLockLegalHold = Shapes::StructureShape.new(name: 'ObjectLockLegalHold')
    ObjectLockLegalHoldStatus = Shapes::StringShape.new(name: 'ObjectLockLegalHoldStatus')
    ObjectLockMode = Shapes::StringShape.new(name: 'ObjectLockMode')
    ObjectLockRetainUntilDate = Shapes::TimestampShape.new(name: 'ObjectLockRetainUntilDate', timestampFormat: "iso8601")
    ObjectLockRetention = Shapes::StructureShape.new(name: 'ObjectLockRetention')
    ObjectLockRetentionMode = Shapes::StringShape.new(name: 'ObjectLockRetentionMode')
    ObjectLockRule = Shapes::StructureShape.new(name: 'ObjectLockRule')
    ObjectLockToken = Shapes::StringShape.new(name: 'ObjectLockToken')
    ObjectNotInActiveTierError = Shapes::StructureShape.new(name: 'ObjectNotInActiveTierError')
    ObjectOwnership = Shapes::StringShape.new(name: 'ObjectOwnership')
    ObjectPart = Shapes::StructureShape.new(name: 'ObjectPart')
    ObjectSize = Shapes::IntegerShape.new(name: 'ObjectSize')
    ObjectSizeGreaterThanBytes = Shapes::IntegerShape.new(name: 'ObjectSizeGreaterThanBytes')
    ObjectSizeLessThanBytes = Shapes::IntegerShape.new(name: 'ObjectSizeLessThanBytes')
    ObjectStorageClass = Shapes::StringShape.new(name: 'ObjectStorageClass')
    ObjectVersion = Shapes::StructureShape.new(name: 'ObjectVersion')
    ObjectVersionId = Shapes::StringShape.new(name: 'ObjectVersionId')
    ObjectVersionList = Shapes::ListShape.new(name: 'ObjectVersionList', flattened: true)
    ObjectVersionStorageClass = Shapes::StringShape.new(name: 'ObjectVersionStorageClass')
    OutputLocation = Shapes::StructureShape.new(name: 'OutputLocation')
    OutputSerialization = Shapes::StructureShape.new(name: 'OutputSerialization')
    Owner = Shapes::StructureShape.new(name: 'Owner')
    OwnerOverride = Shapes::StringShape.new(name: 'OwnerOverride')
    OwnershipControls = Shapes::StructureShape.new(name: 'OwnershipControls')
    OwnershipControlsRule = Shapes::StructureShape.new(name: 'OwnershipControlsRule')
    OwnershipControlsRules = Shapes::ListShape.new(name: 'OwnershipControlsRules', flattened: true)
    ParquetInput = Shapes::StructureShape.new(name: 'ParquetInput')
    Part = Shapes::StructureShape.new(name: 'Part')
    PartNumber = Shapes::IntegerShape.new(name: 'PartNumber')
    PartNumberMarker = Shapes::IntegerShape.new(name: 'PartNumberMarker')
    Parts = Shapes::ListShape.new(name: 'Parts', flattened: true)
    PartsCount = Shapes::IntegerShape.new(name: 'PartsCount')
    PartsList = Shapes::ListShape.new(name: 'PartsList', flattened: true)
    Payer = Shapes::StringShape.new(name: 'Payer')
    Permission = Shapes::StringShape.new(name: 'Permission')
    Policy = Shapes::StringShape.new(name: 'Policy')
    PolicyStatus = Shapes::StructureShape.new(name: 'PolicyStatus')
    Prefix = Shapes::StringShape.new(name: 'Prefix')
    Priority = Shapes::IntegerShape.new(name: 'Priority')
    Progress = Shapes::StructureShape.new(name: 'Progress')
    ProgressEvent = Shapes::StructureShape.new(name: 'ProgressEvent')
    Protocol = Shapes::StringShape.new(name: 'Protocol')
    PublicAccessBlockConfiguration = Shapes::StructureShape.new(name: 'PublicAccessBlockConfiguration')
    PutBucketAccelerateConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketAccelerateConfigurationRequest')
    PutBucketAclRequest = Shapes::StructureShape.new(name: 'PutBucketAclRequest')
    PutBucketAnalyticsConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketAnalyticsConfigurationRequest')
    PutBucketCorsRequest = Shapes::StructureShape.new(name: 'PutBucketCorsRequest')
    PutBucketEncryptionRequest = Shapes::StructureShape.new(name: 'PutBucketEncryptionRequest')
    PutBucketIntelligentTieringConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketIntelligentTieringConfigurationRequest')
    PutBucketInventoryConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketInventoryConfigurationRequest')
    PutBucketLifecycleConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketLifecycleConfigurationRequest')
    PutBucketLifecycleRequest = Shapes::StructureShape.new(name: 'PutBucketLifecycleRequest')
    PutBucketLoggingRequest = Shapes::StructureShape.new(name: 'PutBucketLoggingRequest')
    PutBucketMetricsConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketMetricsConfigurationRequest')
    PutBucketNotificationConfigurationRequest = Shapes::StructureShape.new(name: 'PutBucketNotificationConfigurationRequest')
    PutBucketNotificationRequest = Shapes::StructureShape.new(name: 'PutBucketNotificationRequest')
    PutBucketOwnershipControlsRequest = Shapes::StructureShape.new(name: 'PutBucketOwnershipControlsRequest')
    PutBucketPolicyRequest = Shapes::StructureShape.new(name: 'PutBucketPolicyRequest')
    PutBucketReplicationRequest = Shapes::StructureShape.new(name: 'PutBucketReplicationRequest')
    PutBucketRequestPaymentRequest = Shapes::StructureShape.new(name: 'PutBucketRequestPaymentRequest')
    PutBucketTaggingRequest = Shapes::StructureShape.new(name: 'PutBucketTaggingRequest')
    PutBucketVersioningRequest = Shapes::StructureShape.new(name: 'PutBucketVersioningRequest')
    PutBucketWebsiteRequest = Shapes::StructureShape.new(name: 'PutBucketWebsiteRequest')
    PutObjectAclOutput = Shapes::StructureShape.new(name: 'PutObjectAclOutput')
    PutObjectAclRequest = Shapes::StructureShape.new(name: 'PutObjectAclRequest')
    PutObjectLegalHoldOutput = Shapes::StructureShape.new(name: 'PutObjectLegalHoldOutput')
    PutObjectLegalHoldRequest = Shapes::StructureShape.new(name: 'PutObjectLegalHoldRequest')
    PutObjectLockConfigurationOutput = Shapes::StructureShape.new(name: 'PutObjectLockConfigurationOutput')
    PutObjectLockConfigurationRequest = Shapes::StructureShape.new(name: 'PutObjectLockConfigurationRequest')
    PutObjectOutput = Shapes::StructureShape.new(name: 'PutObjectOutput')
    PutObjectRequest = Shapes::StructureShape.new(name: 'PutObjectRequest')
    PutObjectRetentionOutput = Shapes::StructureShape.new(name: 'PutObjectRetentionOutput')
    PutObjectRetentionRequest = Shapes::StructureShape.new(name: 'PutObjectRetentionRequest')
    PutObjectTaggingOutput = Shapes::StructureShape.new(name: 'PutObjectTaggingOutput')
    PutObjectTaggingRequest = Shapes::StructureShape.new(name: 'PutObjectTaggingRequest')
    PutPublicAccessBlockRequest = Shapes::StructureShape.new(name: 'PutPublicAccessBlockRequest')
    QueueArn = Shapes::StringShape.new(name: 'QueueArn')
    QueueConfiguration = Shapes::StructureShape.new(name: 'QueueConfiguration')
    QueueConfigurationDeprecated = Shapes::StructureShape.new(name: 'QueueConfigurationDeprecated')
    QueueConfigurationList = Shapes::ListShape.new(name: 'QueueConfigurationList', flattened: true)
    Quiet = Shapes::BooleanShape.new(name: 'Quiet')
    QuoteCharacter = Shapes::StringShape.new(name: 'QuoteCharacter')
    QuoteEscapeCharacter = Shapes::StringShape.new(name: 'QuoteEscapeCharacter')
    QuoteFields = Shapes::StringShape.new(name: 'QuoteFields')
    Range = Shapes::StringShape.new(name: 'Range')
    RecordDelimiter = Shapes::StringShape.new(name: 'RecordDelimiter')
    RecordsEvent = Shapes::StructureShape.new(name: 'RecordsEvent')
    Redirect = Shapes::StructureShape.new(name: 'Redirect')
    RedirectAllRequestsTo = Shapes::StructureShape.new(name: 'RedirectAllRequestsTo')
    ReplaceKeyPrefixWith = Shapes::StringShape.new(name: 'ReplaceKeyPrefixWith')
    ReplaceKeyWith = Shapes::StringShape.new(name: 'ReplaceKeyWith')
    ReplicaKmsKeyID = Shapes::StringShape.new(name: 'ReplicaKmsKeyID')
    ReplicaModifications = Shapes::StructureShape.new(name: 'ReplicaModifications')
    ReplicaModificationsStatus = Shapes::StringShape.new(name: 'ReplicaModificationsStatus')
    ReplicationConfiguration = Shapes::StructureShape.new(name: 'ReplicationConfiguration')
    ReplicationRule = Shapes::StructureShape.new(name: 'ReplicationRule')
    ReplicationRuleAndOperator = Shapes::StructureShape.new(name: 'ReplicationRuleAndOperator')
    ReplicationRuleFilter = Shapes::StructureShape.new(name: 'ReplicationRuleFilter')
    ReplicationRuleStatus = Shapes::StringShape.new(name: 'ReplicationRuleStatus')
    ReplicationRules = Shapes::ListShape.new(name: 'ReplicationRules', flattened: true)
    ReplicationStatus = Shapes::StringShape.new(name: 'ReplicationStatus')
    ReplicationTime = Shapes::StructureShape.new(name: 'ReplicationTime')
    ReplicationTimeStatus = Shapes::StringShape.new(name: 'ReplicationTimeStatus')
    ReplicationTimeValue = Shapes::StructureShape.new(name: 'ReplicationTimeValue')
    RequestCharged = Shapes::StringShape.new(name: 'RequestCharged')
    RequestPayer = Shapes::StringShape.new(name: 'RequestPayer')
    RequestPaymentConfiguration = Shapes::StructureShape.new(name: 'RequestPaymentConfiguration')
    RequestProgress = Shapes::StructureShape.new(name: 'RequestProgress')
    RequestRoute = Shapes::StringShape.new(name: 'RequestRoute')
    RequestToken = Shapes::StringShape.new(name: 'RequestToken')
    ResponseCacheControl = Shapes::StringShape.new(name: 'ResponseCacheControl')
    ResponseContentDisposition = Shapes::StringShape.new(name: 'ResponseContentDisposition')
    ResponseContentEncoding = Shapes::StringShape.new(name: 'ResponseContentEncoding')
    ResponseContentLanguage = Shapes::StringShape.new(name: 'ResponseContentLanguage')
    ResponseContentType = Shapes::StringShape.new(name: 'ResponseContentType')
    ResponseExpires = Shapes::TimestampShape.new(name: 'ResponseExpires', timestampFormat: "rfc822")
    Restore = Shapes::StringShape.new(name: 'Restore')
    RestoreObjectOutput = Shapes::StructureShape.new(name: 'RestoreObjectOutput')
    RestoreObjectRequest = Shapes::StructureShape.new(name: 'RestoreObjectRequest')
    RestoreOutputPath = Shapes::StringShape.new(name: 'RestoreOutputPath')
    RestoreRequest = Shapes::StructureShape.new(name: 'RestoreRequest')
    RestoreRequestType = Shapes::StringShape.new(name: 'RestoreRequestType')
    Role = Shapes::StringShape.new(name: 'Role')
    RoutingRule = Shapes::StructureShape.new(name: 'RoutingRule')
    RoutingRules = Shapes::ListShape.new(name: 'RoutingRules')
    Rule = Shapes::StructureShape.new(name: 'Rule')
    Rules = Shapes::ListShape.new(name: 'Rules', flattened: true)
    S3KeyFilter = Shapes::StructureShape.new(name: 'S3KeyFilter')
    S3Location = Shapes::StructureShape.new(name: 'S3Location')
    SSECustomerAlgorithm = Shapes::StringShape.new(name: 'SSECustomerAlgorithm')
    SSECustomerKey = Shapes::StringShape.new(name: 'SSECustomerKey')
    SSECustomerKeyMD5 = Shapes::StringShape.new(name: 'SSECustomerKeyMD5')
    SSEKMS = Shapes::StructureShape.new(name: 'SSEKMS')
    SSEKMSEncryptionContext = Shapes::StringShape.new(name: 'SSEKMSEncryptionContext')
    SSEKMSKeyId = Shapes::StringShape.new(name: 'SSEKMSKeyId')
    SSES3 = Shapes::StructureShape.new(name: 'SSES3')
    ScanRange = Shapes::StructureShape.new(name: 'ScanRange')
    SelectObjectContentEventStream = Shapes::StructureShape.new(name: 'SelectObjectContentEventStream')
    SelectObjectContentOutput = Shapes::StructureShape.new(name: 'SelectObjectContentOutput')
    SelectObjectContentRequest = Shapes::StructureShape.new(name: 'SelectObjectContentRequest')
    SelectParameters = Shapes::StructureShape.new(name: 'SelectParameters')
    ServerSideEncryption = Shapes::StringShape.new(name: 'ServerSideEncryption')
    ServerSideEncryptionByDefault = Shapes::StructureShape.new(name: 'ServerSideEncryptionByDefault')
    ServerSideEncryptionConfiguration = Shapes::StructureShape.new(name: 'ServerSideEncryptionConfiguration')
    ServerSideEncryptionRule = Shapes::StructureShape.new(name: 'ServerSideEncryptionRule')
    ServerSideEncryptionRules = Shapes::ListShape.new(name: 'ServerSideEncryptionRules', flattened: true)
    Setting = Shapes::BooleanShape.new(name: 'Setting')
    Size = Shapes::IntegerShape.new(name: 'Size')
    SkipValidation = Shapes::BooleanShape.new(name: 'SkipValidation')
    SourceSelectionCriteria = Shapes::StructureShape.new(name: 'SourceSelectionCriteria')
    SseKmsEncryptedObjects = Shapes::StructureShape.new(name: 'SseKmsEncryptedObjects')
    SseKmsEncryptedObjectsStatus = Shapes::StringShape.new(name: 'SseKmsEncryptedObjectsStatus')
    Start = Shapes::IntegerShape.new(name: 'Start')
    StartAfter = Shapes::StringShape.new(name: 'StartAfter')
    Stats = Shapes::StructureShape.new(name: 'Stats')
    StatsEvent = Shapes::StructureShape.new(name: 'StatsEvent')
    StorageClass = Shapes::StringShape.new(name: 'StorageClass')
    StorageClassAnalysis = Shapes::StructureShape.new(name: 'StorageClassAnalysis')
    StorageClassAnalysisDataExport = Shapes::StructureShape.new(name: 'StorageClassAnalysisDataExport')
    StorageClassAnalysisSchemaVersion = Shapes::StringShape.new(name: 'StorageClassAnalysisSchemaVersion')
    Suffix = Shapes::StringShape.new(name: 'Suffix')
    Tag = Shapes::StructureShape.new(name: 'Tag')
    TagCount = Shapes::IntegerShape.new(name: 'TagCount')
    TagSet = Shapes::ListShape.new(name: 'TagSet')
    Tagging = Shapes::StructureShape.new(name: 'Tagging')
    TaggingDirective = Shapes::StringShape.new(name: 'TaggingDirective')
    TaggingHeader = Shapes::StringShape.new(name: 'TaggingHeader')
    TargetBucket = Shapes::StringShape.new(name: 'TargetBucket')
    TargetGrant = Shapes::StructureShape.new(name: 'TargetGrant')
    TargetGrants = Shapes::ListShape.new(name: 'TargetGrants')
    TargetPrefix = Shapes::StringShape.new(name: 'TargetPrefix')
    Tier = Shapes::StringShape.new(name: 'Tier')
    Tiering = Shapes::StructureShape.new(name: 'Tiering')
    TieringList = Shapes::ListShape.new(name: 'TieringList', flattened: true)
    Token = Shapes::StringShape.new(name: 'Token')
    TopicArn = Shapes::StringShape.new(name: 'TopicArn')
    TopicConfiguration = Shapes::StructureShape.new(name: 'TopicConfiguration')
    TopicConfigurationDeprecated = Shapes::StructureShape.new(name: 'TopicConfigurationDeprecated')
    TopicConfigurationList = Shapes::ListShape.new(name: 'TopicConfigurationList', flattened: true)
    Transition = Shapes::StructureShape.new(name: 'Transition')
    TransitionList = Shapes::ListShape.new(name: 'TransitionList', flattened: true)
    TransitionStorageClass = Shapes::StringShape.new(name: 'TransitionStorageClass')
    Type = Shapes::StringShape.new(name: 'Type')
    URI = Shapes::StringShape.new(name: 'URI')
    UploadIdMarker = Shapes::StringShape.new(name: 'UploadIdMarker')
    UploadPartCopyOutput = Shapes::StructureShape.new(name: 'UploadPartCopyOutput')
    UploadPartCopyRequest = Shapes::StructureShape.new(name: 'UploadPartCopyRequest')
    UploadPartOutput = Shapes::StructureShape.new(name: 'UploadPartOutput')
    UploadPartRequest = Shapes::StructureShape.new(name: 'UploadPartRequest')
    UserMetadata = Shapes::ListShape.new(name: 'UserMetadata')
    Value = Shapes::StringShape.new(name: 'Value')
    VersionCount = Shapes::IntegerShape.new(name: 'VersionCount')
    VersionIdMarker = Shapes::StringShape.new(name: 'VersionIdMarker')
    VersioningConfiguration = Shapes::StructureShape.new(name: 'VersioningConfiguration')
    WebsiteConfiguration = Shapes::StructureShape.new(name: 'WebsiteConfiguration')
    WebsiteRedirectLocation = Shapes::StringShape.new(name: 'WebsiteRedirectLocation')
    WriteGetObjectResponseRequest = Shapes::StructureShape.new(name: 'WriteGetObjectResponseRequest')
    Years = Shapes::IntegerShape.new(name: 'Years')

    AbortIncompleteMultipartUpload.add_member(:days_after_initiation, Shapes::ShapeRef.new(shape: DaysAfterInitiation, location_name: "DaysAfterInitiation"))
    AbortIncompleteMultipartUpload.struct_class = Types::AbortIncompleteMultipartUpload

    AbortMultipartUploadOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    AbortMultipartUploadOutput.struct_class = Types::AbortMultipartUploadOutput

    AbortMultipartUploadRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    AbortMultipartUploadRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    AbortMultipartUploadRequest.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, required: true, location: "querystring", location_name: "uploadId"))
    AbortMultipartUploadRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    AbortMultipartUploadRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    AbortMultipartUploadRequest.struct_class = Types::AbortMultipartUploadRequest

    AccelerateConfiguration.add_member(:status, Shapes::ShapeRef.new(shape: BucketAccelerateStatus, location_name: "Status"))
    AccelerateConfiguration.struct_class = Types::AccelerateConfiguration

    AccessControlPolicy.add_member(:grants, Shapes::ShapeRef.new(shape: Grants, location_name: "AccessControlList"))
    AccessControlPolicy.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    AccessControlPolicy.struct_class = Types::AccessControlPolicy

    AccessControlTranslation.add_member(:owner, Shapes::ShapeRef.new(shape: OwnerOverride, required: true, location_name: "Owner"))
    AccessControlTranslation.struct_class = Types::AccessControlTranslation

    AllowedHeaders.member = Shapes::ShapeRef.new(shape: AllowedHeader)

    AllowedMethods.member = Shapes::ShapeRef.new(shape: AllowedMethod)

    AllowedOrigins.member = Shapes::ShapeRef.new(shape: AllowedOrigin)

    AnalyticsAndOperator.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    AnalyticsAndOperator.add_member(:tags, Shapes::ShapeRef.new(shape: TagSet, location_name: "Tag", metadata: {"flattened"=>true}))
    AnalyticsAndOperator.struct_class = Types::AnalyticsAndOperator

    AnalyticsConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: AnalyticsId, required: true, location_name: "Id"))
    AnalyticsConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: AnalyticsFilter, location_name: "Filter"))
    AnalyticsConfiguration.add_member(:storage_class_analysis, Shapes::ShapeRef.new(shape: StorageClassAnalysis, required: true, location_name: "StorageClassAnalysis"))
    AnalyticsConfiguration.struct_class = Types::AnalyticsConfiguration

    AnalyticsConfigurationList.member = Shapes::ShapeRef.new(shape: AnalyticsConfiguration)

    AnalyticsExportDestination.add_member(:s3_bucket_destination, Shapes::ShapeRef.new(shape: AnalyticsS3BucketDestination, required: true, location_name: "S3BucketDestination"))
    AnalyticsExportDestination.struct_class = Types::AnalyticsExportDestination

    AnalyticsFilter.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    AnalyticsFilter.add_member(:tag, Shapes::ShapeRef.new(shape: Tag, location_name: "Tag"))
    AnalyticsFilter.add_member(:and, Shapes::ShapeRef.new(shape: AnalyticsAndOperator, location_name: "And"))
    AnalyticsFilter.struct_class = Types::AnalyticsFilter

    AnalyticsS3BucketDestination.add_member(:format, Shapes::ShapeRef.new(shape: AnalyticsS3ExportFileFormat, required: true, location_name: "Format"))
    AnalyticsS3BucketDestination.add_member(:bucket_account_id, Shapes::ShapeRef.new(shape: AccountId, location_name: "BucketAccountId"))
    AnalyticsS3BucketDestination.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location_name: "Bucket"))
    AnalyticsS3BucketDestination.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    AnalyticsS3BucketDestination.struct_class = Types::AnalyticsS3BucketDestination

    Bucket.add_member(:name, Shapes::ShapeRef.new(shape: BucketName, location_name: "Name"))
    Bucket.add_member(:creation_date, Shapes::ShapeRef.new(shape: CreationDate, location_name: "CreationDate"))
    Bucket.struct_class = Types::Bucket

    BucketAlreadyExists.struct_class = Types::BucketAlreadyExists

    BucketAlreadyOwnedByYou.struct_class = Types::BucketAlreadyOwnedByYou

    BucketLifecycleConfiguration.add_member(:rules, Shapes::ShapeRef.new(shape: LifecycleRules, required: true, location_name: "Rule"))
    BucketLifecycleConfiguration.struct_class = Types::BucketLifecycleConfiguration

    BucketLoggingStatus.add_member(:logging_enabled, Shapes::ShapeRef.new(shape: LoggingEnabled, location_name: "LoggingEnabled"))
    BucketLoggingStatus.struct_class = Types::BucketLoggingStatus

    Buckets.member = Shapes::ShapeRef.new(shape: Bucket, location_name: "Bucket")

    CORSConfiguration.add_member(:cors_rules, Shapes::ShapeRef.new(shape: CORSRules, required: true, location_name: "CORSRule"))
    CORSConfiguration.struct_class = Types::CORSConfiguration

    CORSRule.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    CORSRule.add_member(:allowed_headers, Shapes::ShapeRef.new(shape: AllowedHeaders, location_name: "AllowedHeader"))
    CORSRule.add_member(:allowed_methods, Shapes::ShapeRef.new(shape: AllowedMethods, required: true, location_name: "AllowedMethod"))
    CORSRule.add_member(:allowed_origins, Shapes::ShapeRef.new(shape: AllowedOrigins, required: true, location_name: "AllowedOrigin"))
    CORSRule.add_member(:expose_headers, Shapes::ShapeRef.new(shape: ExposeHeaders, location_name: "ExposeHeader"))
    CORSRule.add_member(:max_age_seconds, Shapes::ShapeRef.new(shape: MaxAgeSeconds, location_name: "MaxAgeSeconds"))
    CORSRule.struct_class = Types::CORSRule

    CORSRules.member = Shapes::ShapeRef.new(shape: CORSRule)

    CSVInput.add_member(:file_header_info, Shapes::ShapeRef.new(shape: FileHeaderInfo, location_name: "FileHeaderInfo"))
    CSVInput.add_member(:comments, Shapes::ShapeRef.new(shape: Comments, location_name: "Comments"))
    CSVInput.add_member(:quote_escape_character, Shapes::ShapeRef.new(shape: QuoteEscapeCharacter, location_name: "QuoteEscapeCharacter"))
    CSVInput.add_member(:record_delimiter, Shapes::ShapeRef.new(shape: RecordDelimiter, location_name: "RecordDelimiter"))
    CSVInput.add_member(:field_delimiter, Shapes::ShapeRef.new(shape: FieldDelimiter, location_name: "FieldDelimiter"))
    CSVInput.add_member(:quote_character, Shapes::ShapeRef.new(shape: QuoteCharacter, location_name: "QuoteCharacter"))
    CSVInput.add_member(:allow_quoted_record_delimiter, Shapes::ShapeRef.new(shape: AllowQuotedRecordDelimiter, location_name: "AllowQuotedRecordDelimiter"))
    CSVInput.struct_class = Types::CSVInput

    CSVOutput.add_member(:quote_fields, Shapes::ShapeRef.new(shape: QuoteFields, location_name: "QuoteFields"))
    CSVOutput.add_member(:quote_escape_character, Shapes::ShapeRef.new(shape: QuoteEscapeCharacter, location_name: "QuoteEscapeCharacter"))
    CSVOutput.add_member(:record_delimiter, Shapes::ShapeRef.new(shape: RecordDelimiter, location_name: "RecordDelimiter"))
    CSVOutput.add_member(:field_delimiter, Shapes::ShapeRef.new(shape: FieldDelimiter, location_name: "FieldDelimiter"))
    CSVOutput.add_member(:quote_character, Shapes::ShapeRef.new(shape: QuoteCharacter, location_name: "QuoteCharacter"))
    CSVOutput.struct_class = Types::CSVOutput

    Checksum.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    Checksum.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    Checksum.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    Checksum.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    Checksum.struct_class = Types::Checksum

    ChecksumAlgorithmList.member = Shapes::ShapeRef.new(shape: ChecksumAlgorithm)

    CloudFunctionConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: NotificationId, location_name: "Id"))
    CloudFunctionConfiguration.add_member(:event, Shapes::ShapeRef.new(shape: Event, deprecated: true, location_name: "Event"))
    CloudFunctionConfiguration.add_member(:events, Shapes::ShapeRef.new(shape: EventList, location_name: "Event"))
    CloudFunctionConfiguration.add_member(:cloud_function, Shapes::ShapeRef.new(shape: CloudFunction, location_name: "CloudFunction"))
    CloudFunctionConfiguration.add_member(:invocation_role, Shapes::ShapeRef.new(shape: CloudFunctionInvocationRole, location_name: "InvocationRole"))
    CloudFunctionConfiguration.struct_class = Types::CloudFunctionConfiguration

    CommonPrefix.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    CommonPrefix.struct_class = Types::CommonPrefix

    CommonPrefixList.member = Shapes::ShapeRef.new(shape: CommonPrefix)

    CompleteMultipartUploadOutput.add_member(:location, Shapes::ShapeRef.new(shape: Location, location_name: "Location"))
    CompleteMultipartUploadOutput.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, location_name: "Bucket"))
    CompleteMultipartUploadOutput.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    CompleteMultipartUploadOutput.add_member(:expiration, Shapes::ShapeRef.new(shape: Expiration, location: "header", location_name: "x-amz-expiration"))
    CompleteMultipartUploadOutput.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    CompleteMultipartUploadOutput.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    CompleteMultipartUploadOutput.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    CompleteMultipartUploadOutput.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    CompleteMultipartUploadOutput.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    CompleteMultipartUploadOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    CompleteMultipartUploadOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    CompleteMultipartUploadOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    CompleteMultipartUploadOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    CompleteMultipartUploadOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    CompleteMultipartUploadOutput.struct_class = Types::CompleteMultipartUploadOutput

    CompleteMultipartUploadRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    CompleteMultipartUploadRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    CompleteMultipartUploadRequest.add_member(:multipart_upload, Shapes::ShapeRef.new(shape: CompletedMultipartUpload, location_name: "CompleteMultipartUpload", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    CompleteMultipartUploadRequest.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, required: true, location: "querystring", location_name: "uploadId"))
    CompleteMultipartUploadRequest.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    CompleteMultipartUploadRequest.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    CompleteMultipartUploadRequest.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    CompleteMultipartUploadRequest.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    CompleteMultipartUploadRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    CompleteMultipartUploadRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    CompleteMultipartUploadRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    CompleteMultipartUploadRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    CompleteMultipartUploadRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    CompleteMultipartUploadRequest.struct_class = Types::CompleteMultipartUploadRequest
    CompleteMultipartUploadRequest[:payload] = :multipart_upload
    CompleteMultipartUploadRequest[:payload_member] = CompleteMultipartUploadRequest.member(:multipart_upload)

    CompletedMultipartUpload.add_member(:parts, Shapes::ShapeRef.new(shape: CompletedPartList, location_name: "Part"))
    CompletedMultipartUpload.struct_class = Types::CompletedMultipartUpload

    CompletedPart.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    CompletedPart.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    CompletedPart.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    CompletedPart.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    CompletedPart.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    CompletedPart.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, location_name: "PartNumber"))
    CompletedPart.struct_class = Types::CompletedPart

    CompletedPartList.member = Shapes::ShapeRef.new(shape: CompletedPart)

    Condition.add_member(:http_error_code_returned_equals, Shapes::ShapeRef.new(shape: HttpErrorCodeReturnedEquals, location_name: "HttpErrorCodeReturnedEquals"))
    Condition.add_member(:key_prefix_equals, Shapes::ShapeRef.new(shape: KeyPrefixEquals, location_name: "KeyPrefixEquals"))
    Condition.struct_class = Types::Condition

    ContinuationEvent.struct_class = Types::ContinuationEvent

    CopyObjectOutput.add_member(:copy_object_result, Shapes::ShapeRef.new(shape: CopyObjectResult, location_name: "CopyObjectResult"))
    CopyObjectOutput.add_member(:expiration, Shapes::ShapeRef.new(shape: Expiration, location: "header", location_name: "x-amz-expiration"))
    CopyObjectOutput.add_member(:copy_source_version_id, Shapes::ShapeRef.new(shape: CopySourceVersionId, location: "header", location_name: "x-amz-copy-source-version-id"))
    CopyObjectOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    CopyObjectOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    CopyObjectOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    CopyObjectOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    CopyObjectOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    CopyObjectOutput.add_member(:ssekms_encryption_context, Shapes::ShapeRef.new(shape: SSEKMSEncryptionContext, location: "header", location_name: "x-amz-server-side-encryption-context"))
    CopyObjectOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    CopyObjectOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    CopyObjectOutput.struct_class = Types::CopyObjectOutput
    CopyObjectOutput[:payload] = :copy_object_result
    CopyObjectOutput[:payload_member] = CopyObjectOutput.member(:copy_object_result)

    CopyObjectRequest.add_member(:acl, Shapes::ShapeRef.new(shape: ObjectCannedACL, location: "header", location_name: "x-amz-acl"))
    CopyObjectRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    CopyObjectRequest.add_member(:cache_control, Shapes::ShapeRef.new(shape: CacheControl, location: "header", location_name: "Cache-Control"))
    CopyObjectRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-checksum-algorithm"))
    CopyObjectRequest.add_member(:content_disposition, Shapes::ShapeRef.new(shape: ContentDisposition, location: "header", location_name: "Content-Disposition"))
    CopyObjectRequest.add_member(:content_encoding, Shapes::ShapeRef.new(shape: ContentEncoding, location: "header", location_name: "Content-Encoding"))
    CopyObjectRequest.add_member(:content_language, Shapes::ShapeRef.new(shape: ContentLanguage, location: "header", location_name: "Content-Language"))
    CopyObjectRequest.add_member(:content_type, Shapes::ShapeRef.new(shape: ContentType, location: "header", location_name: "Content-Type"))
    CopyObjectRequest.add_member(:copy_source, Shapes::ShapeRef.new(shape: CopySource, required: true, location: "header", location_name: "x-amz-copy-source"))
    CopyObjectRequest.add_member(:copy_source_if_match, Shapes::ShapeRef.new(shape: CopySourceIfMatch, location: "header", location_name: "x-amz-copy-source-if-match"))
    CopyObjectRequest.add_member(:copy_source_if_modified_since, Shapes::ShapeRef.new(shape: CopySourceIfModifiedSince, location: "header", location_name: "x-amz-copy-source-if-modified-since"))
    CopyObjectRequest.add_member(:copy_source_if_none_match, Shapes::ShapeRef.new(shape: CopySourceIfNoneMatch, location: "header", location_name: "x-amz-copy-source-if-none-match"))
    CopyObjectRequest.add_member(:copy_source_if_unmodified_since, Shapes::ShapeRef.new(shape: CopySourceIfUnmodifiedSince, location: "header", location_name: "x-amz-copy-source-if-unmodified-since"))
    CopyObjectRequest.add_member(:expires, Shapes::ShapeRef.new(shape: Expires, location: "header", location_name: "Expires"))
    CopyObjectRequest.add_member(:grant_full_control, Shapes::ShapeRef.new(shape: GrantFullControl, location: "header", location_name: "x-amz-grant-full-control"))
    CopyObjectRequest.add_member(:grant_read, Shapes::ShapeRef.new(shape: GrantRead, location: "header", location_name: "x-amz-grant-read"))
    CopyObjectRequest.add_member(:grant_read_acp, Shapes::ShapeRef.new(shape: GrantReadACP, location: "header", location_name: "x-amz-grant-read-acp"))
    CopyObjectRequest.add_member(:grant_write_acp, Shapes::ShapeRef.new(shape: GrantWriteACP, location: "header", location_name: "x-amz-grant-write-acp"))
    CopyObjectRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    CopyObjectRequest.add_member(:metadata, Shapes::ShapeRef.new(shape: Metadata, location: "headers", location_name: "x-amz-meta-"))
    CopyObjectRequest.add_member(:metadata_directive, Shapes::ShapeRef.new(shape: MetadataDirective, location: "header", location_name: "x-amz-metadata-directive"))
    CopyObjectRequest.add_member(:tagging_directive, Shapes::ShapeRef.new(shape: TaggingDirective, location: "header", location_name: "x-amz-tagging-directive"))
    CopyObjectRequest.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    CopyObjectRequest.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location: "header", location_name: "x-amz-storage-class"))
    CopyObjectRequest.add_member(:website_redirect_location, Shapes::ShapeRef.new(shape: WebsiteRedirectLocation, location: "header", location_name: "x-amz-website-redirect-location"))
    CopyObjectRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    CopyObjectRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    CopyObjectRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    CopyObjectRequest.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    CopyObjectRequest.add_member(:ssekms_encryption_context, Shapes::ShapeRef.new(shape: SSEKMSEncryptionContext, location: "header", location_name: "x-amz-server-side-encryption-context"))
    CopyObjectRequest.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    CopyObjectRequest.add_member(:copy_source_sse_customer_algorithm, Shapes::ShapeRef.new(shape: CopySourceSSECustomerAlgorithm, location: "header", location_name: "x-amz-copy-source-server-side-encryption-customer-algorithm"))
    CopyObjectRequest.add_member(:copy_source_sse_customer_key, Shapes::ShapeRef.new(shape: CopySourceSSECustomerKey, location: "header", location_name: "x-amz-copy-source-server-side-encryption-customer-key"))
    CopyObjectRequest.add_member(:copy_source_sse_customer_key_md5, Shapes::ShapeRef.new(shape: CopySourceSSECustomerKeyMD5, location: "header", location_name: "x-amz-copy-source-server-side-encryption-customer-key-MD5"))
    CopyObjectRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    CopyObjectRequest.add_member(:tagging, Shapes::ShapeRef.new(shape: TaggingHeader, location: "header", location_name: "x-amz-tagging"))
    CopyObjectRequest.add_member(:object_lock_mode, Shapes::ShapeRef.new(shape: ObjectLockMode, location: "header", location_name: "x-amz-object-lock-mode"))
    CopyObjectRequest.add_member(:object_lock_retain_until_date, Shapes::ShapeRef.new(shape: ObjectLockRetainUntilDate, location: "header", location_name: "x-amz-object-lock-retain-until-date"))
    CopyObjectRequest.add_member(:object_lock_legal_hold_status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location: "header", location_name: "x-amz-object-lock-legal-hold"))
    CopyObjectRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    CopyObjectRequest.add_member(:expected_source_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-source-expected-bucket-owner"))
    CopyObjectRequest.struct_class = Types::CopyObjectRequest

    CopyObjectResult.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    CopyObjectResult.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location_name: "LastModified"))
    CopyObjectResult.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    CopyObjectResult.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    CopyObjectResult.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    CopyObjectResult.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    CopyObjectResult.struct_class = Types::CopyObjectResult

    CopyPartResult.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    CopyPartResult.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location_name: "LastModified"))
    CopyPartResult.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    CopyPartResult.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    CopyPartResult.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    CopyPartResult.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    CopyPartResult.struct_class = Types::CopyPartResult

    CreateBucketConfiguration.add_member(:location_constraint, Shapes::ShapeRef.new(shape: BucketLocationConstraint, location_name: "LocationConstraint"))
    CreateBucketConfiguration.struct_class = Types::CreateBucketConfiguration

    CreateBucketOutput.add_member(:location, Shapes::ShapeRef.new(shape: Location, location: "header", location_name: "Location"))
    CreateBucketOutput.struct_class = Types::CreateBucketOutput

    CreateBucketRequest.add_member(:acl, Shapes::ShapeRef.new(shape: BucketCannedACL, location: "header", location_name: "x-amz-acl"))
    CreateBucketRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    CreateBucketRequest.add_member(:create_bucket_configuration, Shapes::ShapeRef.new(shape: CreateBucketConfiguration, location_name: "CreateBucketConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    CreateBucketRequest.add_member(:grant_full_control, Shapes::ShapeRef.new(shape: GrantFullControl, location: "header", location_name: "x-amz-grant-full-control"))
    CreateBucketRequest.add_member(:grant_read, Shapes::ShapeRef.new(shape: GrantRead, location: "header", location_name: "x-amz-grant-read"))
    CreateBucketRequest.add_member(:grant_read_acp, Shapes::ShapeRef.new(shape: GrantReadACP, location: "header", location_name: "x-amz-grant-read-acp"))
    CreateBucketRequest.add_member(:grant_write, Shapes::ShapeRef.new(shape: GrantWrite, location: "header", location_name: "x-amz-grant-write"))
    CreateBucketRequest.add_member(:grant_write_acp, Shapes::ShapeRef.new(shape: GrantWriteACP, location: "header", location_name: "x-amz-grant-write-acp"))
    CreateBucketRequest.add_member(:object_lock_enabled_for_bucket, Shapes::ShapeRef.new(shape: ObjectLockEnabledForBucket, location: "header", location_name: "x-amz-bucket-object-lock-enabled"))
    CreateBucketRequest.add_member(:object_ownership, Shapes::ShapeRef.new(shape: ObjectOwnership, location: "header", location_name: "x-amz-object-ownership"))
    CreateBucketRequest.struct_class = Types::CreateBucketRequest
    CreateBucketRequest[:payload] = :create_bucket_configuration
    CreateBucketRequest[:payload_member] = CreateBucketRequest.member(:create_bucket_configuration)

    CreateMultipartUploadOutput.add_member(:abort_date, Shapes::ShapeRef.new(shape: AbortDate, location: "header", location_name: "x-amz-abort-date"))
    CreateMultipartUploadOutput.add_member(:abort_rule_id, Shapes::ShapeRef.new(shape: AbortRuleId, location: "header", location_name: "x-amz-abort-rule-id"))
    CreateMultipartUploadOutput.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, location_name: "Bucket"))
    CreateMultipartUploadOutput.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    CreateMultipartUploadOutput.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, location_name: "UploadId"))
    CreateMultipartUploadOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    CreateMultipartUploadOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    CreateMultipartUploadOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    CreateMultipartUploadOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    CreateMultipartUploadOutput.add_member(:ssekms_encryption_context, Shapes::ShapeRef.new(shape: SSEKMSEncryptionContext, location: "header", location_name: "x-amz-server-side-encryption-context"))
    CreateMultipartUploadOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    CreateMultipartUploadOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    CreateMultipartUploadOutput.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-checksum-algorithm"))
    CreateMultipartUploadOutput.struct_class = Types::CreateMultipartUploadOutput

    CreateMultipartUploadRequest.add_member(:acl, Shapes::ShapeRef.new(shape: ObjectCannedACL, location: "header", location_name: "x-amz-acl"))
    CreateMultipartUploadRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    CreateMultipartUploadRequest.add_member(:cache_control, Shapes::ShapeRef.new(shape: CacheControl, location: "header", location_name: "Cache-Control"))
    CreateMultipartUploadRequest.add_member(:content_disposition, Shapes::ShapeRef.new(shape: ContentDisposition, location: "header", location_name: "Content-Disposition"))
    CreateMultipartUploadRequest.add_member(:content_encoding, Shapes::ShapeRef.new(shape: ContentEncoding, location: "header", location_name: "Content-Encoding"))
    CreateMultipartUploadRequest.add_member(:content_language, Shapes::ShapeRef.new(shape: ContentLanguage, location: "header", location_name: "Content-Language"))
    CreateMultipartUploadRequest.add_member(:content_type, Shapes::ShapeRef.new(shape: ContentType, location: "header", location_name: "Content-Type"))
    CreateMultipartUploadRequest.add_member(:expires, Shapes::ShapeRef.new(shape: Expires, location: "header", location_name: "Expires"))
    CreateMultipartUploadRequest.add_member(:grant_full_control, Shapes::ShapeRef.new(shape: GrantFullControl, location: "header", location_name: "x-amz-grant-full-control"))
    CreateMultipartUploadRequest.add_member(:grant_read, Shapes::ShapeRef.new(shape: GrantRead, location: "header", location_name: "x-amz-grant-read"))
    CreateMultipartUploadRequest.add_member(:grant_read_acp, Shapes::ShapeRef.new(shape: GrantReadACP, location: "header", location_name: "x-amz-grant-read-acp"))
    CreateMultipartUploadRequest.add_member(:grant_write_acp, Shapes::ShapeRef.new(shape: GrantWriteACP, location: "header", location_name: "x-amz-grant-write-acp"))
    CreateMultipartUploadRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    CreateMultipartUploadRequest.add_member(:metadata, Shapes::ShapeRef.new(shape: Metadata, location: "headers", location_name: "x-amz-meta-"))
    CreateMultipartUploadRequest.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    CreateMultipartUploadRequest.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location: "header", location_name: "x-amz-storage-class"))
    CreateMultipartUploadRequest.add_member(:website_redirect_location, Shapes::ShapeRef.new(shape: WebsiteRedirectLocation, location: "header", location_name: "x-amz-website-redirect-location"))
    CreateMultipartUploadRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    CreateMultipartUploadRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    CreateMultipartUploadRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    CreateMultipartUploadRequest.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    CreateMultipartUploadRequest.add_member(:ssekms_encryption_context, Shapes::ShapeRef.new(shape: SSEKMSEncryptionContext, location: "header", location_name: "x-amz-server-side-encryption-context"))
    CreateMultipartUploadRequest.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    CreateMultipartUploadRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    CreateMultipartUploadRequest.add_member(:tagging, Shapes::ShapeRef.new(shape: TaggingHeader, location: "header", location_name: "x-amz-tagging"))
    CreateMultipartUploadRequest.add_member(:object_lock_mode, Shapes::ShapeRef.new(shape: ObjectLockMode, location: "header", location_name: "x-amz-object-lock-mode"))
    CreateMultipartUploadRequest.add_member(:object_lock_retain_until_date, Shapes::ShapeRef.new(shape: ObjectLockRetainUntilDate, location: "header", location_name: "x-amz-object-lock-retain-until-date"))
    CreateMultipartUploadRequest.add_member(:object_lock_legal_hold_status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location: "header", location_name: "x-amz-object-lock-legal-hold"))
    CreateMultipartUploadRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    CreateMultipartUploadRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-checksum-algorithm"))
    CreateMultipartUploadRequest.struct_class = Types::CreateMultipartUploadRequest

    DefaultRetention.add_member(:mode, Shapes::ShapeRef.new(shape: ObjectLockRetentionMode, location_name: "Mode"))
    DefaultRetention.add_member(:days, Shapes::ShapeRef.new(shape: Days, location_name: "Days"))
    DefaultRetention.add_member(:years, Shapes::ShapeRef.new(shape: Years, location_name: "Years"))
    DefaultRetention.struct_class = Types::DefaultRetention

    Delete.add_member(:objects, Shapes::ShapeRef.new(shape: ObjectIdentifierList, required: true, location_name: "Object"))
    Delete.add_member(:quiet, Shapes::ShapeRef.new(shape: Quiet, location_name: "Quiet"))
    Delete.struct_class = Types::Delete

    DeleteBucketAnalyticsConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketAnalyticsConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: AnalyticsId, required: true, location: "querystring", location_name: "id"))
    DeleteBucketAnalyticsConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketAnalyticsConfigurationRequest.struct_class = Types::DeleteBucketAnalyticsConfigurationRequest

    DeleteBucketCorsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketCorsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketCorsRequest.struct_class = Types::DeleteBucketCorsRequest

    DeleteBucketEncryptionRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketEncryptionRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketEncryptionRequest.struct_class = Types::DeleteBucketEncryptionRequest

    DeleteBucketIntelligentTieringConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketIntelligentTieringConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: IntelligentTieringId, required: true, location: "querystring", location_name: "id"))
    DeleteBucketIntelligentTieringConfigurationRequest.struct_class = Types::DeleteBucketIntelligentTieringConfigurationRequest

    DeleteBucketInventoryConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketInventoryConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: InventoryId, required: true, location: "querystring", location_name: "id"))
    DeleteBucketInventoryConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketInventoryConfigurationRequest.struct_class = Types::DeleteBucketInventoryConfigurationRequest

    DeleteBucketLifecycleRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketLifecycleRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketLifecycleRequest.struct_class = Types::DeleteBucketLifecycleRequest

    DeleteBucketMetricsConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketMetricsConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: MetricsId, required: true, location: "querystring", location_name: "id"))
    DeleteBucketMetricsConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketMetricsConfigurationRequest.struct_class = Types::DeleteBucketMetricsConfigurationRequest

    DeleteBucketOwnershipControlsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketOwnershipControlsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketOwnershipControlsRequest.struct_class = Types::DeleteBucketOwnershipControlsRequest

    DeleteBucketPolicyRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketPolicyRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketPolicyRequest.struct_class = Types::DeleteBucketPolicyRequest

    DeleteBucketReplicationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketReplicationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketReplicationRequest.struct_class = Types::DeleteBucketReplicationRequest

    DeleteBucketRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketRequest.struct_class = Types::DeleteBucketRequest

    DeleteBucketTaggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketTaggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketTaggingRequest.struct_class = Types::DeleteBucketTaggingRequest

    DeleteBucketWebsiteRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteBucketWebsiteRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteBucketWebsiteRequest.struct_class = Types::DeleteBucketWebsiteRequest

    DeleteMarkerEntry.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    DeleteMarkerEntry.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    DeleteMarkerEntry.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location_name: "VersionId"))
    DeleteMarkerEntry.add_member(:is_latest, Shapes::ShapeRef.new(shape: IsLatest, location_name: "IsLatest"))
    DeleteMarkerEntry.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location_name: "LastModified"))
    DeleteMarkerEntry.struct_class = Types::DeleteMarkerEntry

    DeleteMarkerReplication.add_member(:status, Shapes::ShapeRef.new(shape: DeleteMarkerReplicationStatus, location_name: "Status"))
    DeleteMarkerReplication.struct_class = Types::DeleteMarkerReplication

    DeleteMarkers.member = Shapes::ShapeRef.new(shape: DeleteMarkerEntry)

    DeleteObjectOutput.add_member(:delete_marker, Shapes::ShapeRef.new(shape: DeleteMarker, location: "header", location_name: "x-amz-delete-marker"))
    DeleteObjectOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    DeleteObjectOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    DeleteObjectOutput.struct_class = Types::DeleteObjectOutput

    DeleteObjectRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteObjectRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    DeleteObjectRequest.add_member(:mfa, Shapes::ShapeRef.new(shape: MFA, location: "header", location_name: "x-amz-mfa"))
    DeleteObjectRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    DeleteObjectRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    DeleteObjectRequest.add_member(:bypass_governance_retention, Shapes::ShapeRef.new(shape: BypassGovernanceRetention, location: "header", location_name: "x-amz-bypass-governance-retention"))
    DeleteObjectRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteObjectRequest.struct_class = Types::DeleteObjectRequest

    DeleteObjectTaggingOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    DeleteObjectTaggingOutput.struct_class = Types::DeleteObjectTaggingOutput

    DeleteObjectTaggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteObjectTaggingRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    DeleteObjectTaggingRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    DeleteObjectTaggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteObjectTaggingRequest.struct_class = Types::DeleteObjectTaggingRequest

    DeleteObjectsOutput.add_member(:deleted, Shapes::ShapeRef.new(shape: DeletedObjects, location_name: "Deleted"))
    DeleteObjectsOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    DeleteObjectsOutput.add_member(:errors, Shapes::ShapeRef.new(shape: Errors, location_name: "Error"))
    DeleteObjectsOutput.struct_class = Types::DeleteObjectsOutput

    DeleteObjectsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeleteObjectsRequest.add_member(:delete, Shapes::ShapeRef.new(shape: Delete, required: true, location_name: "Delete", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    DeleteObjectsRequest.add_member(:mfa, Shapes::ShapeRef.new(shape: MFA, location: "header", location_name: "x-amz-mfa"))
    DeleteObjectsRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    DeleteObjectsRequest.add_member(:bypass_governance_retention, Shapes::ShapeRef.new(shape: BypassGovernanceRetention, location: "header", location_name: "x-amz-bypass-governance-retention"))
    DeleteObjectsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeleteObjectsRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    DeleteObjectsRequest.struct_class = Types::DeleteObjectsRequest
    DeleteObjectsRequest[:payload] = :delete
    DeleteObjectsRequest[:payload_member] = DeleteObjectsRequest.member(:delete)

    DeletePublicAccessBlockRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    DeletePublicAccessBlockRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    DeletePublicAccessBlockRequest.struct_class = Types::DeletePublicAccessBlockRequest

    DeletedObject.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    DeletedObject.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location_name: "VersionId"))
    DeletedObject.add_member(:delete_marker, Shapes::ShapeRef.new(shape: DeleteMarker, location_name: "DeleteMarker"))
    DeletedObject.add_member(:delete_marker_version_id, Shapes::ShapeRef.new(shape: DeleteMarkerVersionId, location_name: "DeleteMarkerVersionId"))
    DeletedObject.struct_class = Types::DeletedObject

    DeletedObjects.member = Shapes::ShapeRef.new(shape: DeletedObject)

    Destination.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location_name: "Bucket"))
    Destination.add_member(:account, Shapes::ShapeRef.new(shape: AccountId, location_name: "Account"))
    Destination.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location_name: "StorageClass"))
    Destination.add_member(:access_control_translation, Shapes::ShapeRef.new(shape: AccessControlTranslation, location_name: "AccessControlTranslation"))
    Destination.add_member(:encryption_configuration, Shapes::ShapeRef.new(shape: EncryptionConfiguration, location_name: "EncryptionConfiguration"))
    Destination.add_member(:replication_time, Shapes::ShapeRef.new(shape: ReplicationTime, location_name: "ReplicationTime"))
    Destination.add_member(:metrics, Shapes::ShapeRef.new(shape: Metrics, location_name: "Metrics"))
    Destination.struct_class = Types::Destination

    Encryption.add_member(:encryption_type, Shapes::ShapeRef.new(shape: ServerSideEncryption, required: true, location_name: "EncryptionType"))
    Encryption.add_member(:kms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location_name: "KMSKeyId"))
    Encryption.add_member(:kms_context, Shapes::ShapeRef.new(shape: KMSContext, location_name: "KMSContext"))
    Encryption.struct_class = Types::Encryption

    EncryptionConfiguration.add_member(:replica_kms_key_id, Shapes::ShapeRef.new(shape: ReplicaKmsKeyID, location_name: "ReplicaKmsKeyID"))
    EncryptionConfiguration.struct_class = Types::EncryptionConfiguration

    EndEvent.struct_class = Types::EndEvent

    Error.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    Error.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location_name: "VersionId"))
    Error.add_member(:code, Shapes::ShapeRef.new(shape: Code, location_name: "Code"))
    Error.add_member(:message, Shapes::ShapeRef.new(shape: Message, location_name: "Message"))
    Error.struct_class = Types::Error

    ErrorDocument.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location_name: "Key"))
    ErrorDocument.struct_class = Types::ErrorDocument

    Errors.member = Shapes::ShapeRef.new(shape: Error)

    EventBridgeConfiguration.struct_class = Types::EventBridgeConfiguration

    EventList.member = Shapes::ShapeRef.new(shape: Event)

    ExistingObjectReplication.add_member(:status, Shapes::ShapeRef.new(shape: ExistingObjectReplicationStatus, required: true, location_name: "Status"))
    ExistingObjectReplication.struct_class = Types::ExistingObjectReplication

    ExposeHeaders.member = Shapes::ShapeRef.new(shape: ExposeHeader)

    FilterRule.add_member(:name, Shapes::ShapeRef.new(shape: FilterRuleName, location_name: "Name"))
    FilterRule.add_member(:value, Shapes::ShapeRef.new(shape: FilterRuleValue, location_name: "Value"))
    FilterRule.struct_class = Types::FilterRule

    FilterRuleList.member = Shapes::ShapeRef.new(shape: FilterRule)

    GetBucketAccelerateConfigurationOutput.add_member(:status, Shapes::ShapeRef.new(shape: BucketAccelerateStatus, location_name: "Status"))
    GetBucketAccelerateConfigurationOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    GetBucketAccelerateConfigurationOutput.struct_class = Types::GetBucketAccelerateConfigurationOutput

    GetBucketAccelerateConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketAccelerateConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketAccelerateConfigurationRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetBucketAccelerateConfigurationRequest.struct_class = Types::GetBucketAccelerateConfigurationRequest

    GetBucketAclOutput.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    GetBucketAclOutput.add_member(:grants, Shapes::ShapeRef.new(shape: Grants, location_name: "AccessControlList"))
    GetBucketAclOutput.struct_class = Types::GetBucketAclOutput

    GetBucketAclRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketAclRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketAclRequest.struct_class = Types::GetBucketAclRequest

    GetBucketAnalyticsConfigurationOutput.add_member(:analytics_configuration, Shapes::ShapeRef.new(shape: AnalyticsConfiguration, location_name: "AnalyticsConfiguration"))
    GetBucketAnalyticsConfigurationOutput.struct_class = Types::GetBucketAnalyticsConfigurationOutput
    GetBucketAnalyticsConfigurationOutput[:payload] = :analytics_configuration
    GetBucketAnalyticsConfigurationOutput[:payload_member] = GetBucketAnalyticsConfigurationOutput.member(:analytics_configuration)

    GetBucketAnalyticsConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketAnalyticsConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: AnalyticsId, required: true, location: "querystring", location_name: "id"))
    GetBucketAnalyticsConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketAnalyticsConfigurationRequest.struct_class = Types::GetBucketAnalyticsConfigurationRequest

    GetBucketCorsOutput.add_member(:cors_rules, Shapes::ShapeRef.new(shape: CORSRules, location_name: "CORSRule"))
    GetBucketCorsOutput.struct_class = Types::GetBucketCorsOutput

    GetBucketCorsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketCorsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketCorsRequest.struct_class = Types::GetBucketCorsRequest

    GetBucketEncryptionOutput.add_member(:server_side_encryption_configuration, Shapes::ShapeRef.new(shape: ServerSideEncryptionConfiguration, location_name: "ServerSideEncryptionConfiguration"))
    GetBucketEncryptionOutput.struct_class = Types::GetBucketEncryptionOutput
    GetBucketEncryptionOutput[:payload] = :server_side_encryption_configuration
    GetBucketEncryptionOutput[:payload_member] = GetBucketEncryptionOutput.member(:server_side_encryption_configuration)

    GetBucketEncryptionRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketEncryptionRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketEncryptionRequest.struct_class = Types::GetBucketEncryptionRequest

    GetBucketIntelligentTieringConfigurationOutput.add_member(:intelligent_tiering_configuration, Shapes::ShapeRef.new(shape: IntelligentTieringConfiguration, location_name: "IntelligentTieringConfiguration"))
    GetBucketIntelligentTieringConfigurationOutput.struct_class = Types::GetBucketIntelligentTieringConfigurationOutput
    GetBucketIntelligentTieringConfigurationOutput[:payload] = :intelligent_tiering_configuration
    GetBucketIntelligentTieringConfigurationOutput[:payload_member] = GetBucketIntelligentTieringConfigurationOutput.member(:intelligent_tiering_configuration)

    GetBucketIntelligentTieringConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketIntelligentTieringConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: IntelligentTieringId, required: true, location: "querystring", location_name: "id"))
    GetBucketIntelligentTieringConfigurationRequest.struct_class = Types::GetBucketIntelligentTieringConfigurationRequest

    GetBucketInventoryConfigurationOutput.add_member(:inventory_configuration, Shapes::ShapeRef.new(shape: InventoryConfiguration, location_name: "InventoryConfiguration"))
    GetBucketInventoryConfigurationOutput.struct_class = Types::GetBucketInventoryConfigurationOutput
    GetBucketInventoryConfigurationOutput[:payload] = :inventory_configuration
    GetBucketInventoryConfigurationOutput[:payload_member] = GetBucketInventoryConfigurationOutput.member(:inventory_configuration)

    GetBucketInventoryConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketInventoryConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: InventoryId, required: true, location: "querystring", location_name: "id"))
    GetBucketInventoryConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketInventoryConfigurationRequest.struct_class = Types::GetBucketInventoryConfigurationRequest

    GetBucketLifecycleConfigurationOutput.add_member(:rules, Shapes::ShapeRef.new(shape: LifecycleRules, location_name: "Rule"))
    GetBucketLifecycleConfigurationOutput.struct_class = Types::GetBucketLifecycleConfigurationOutput

    GetBucketLifecycleConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketLifecycleConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketLifecycleConfigurationRequest.struct_class = Types::GetBucketLifecycleConfigurationRequest

    GetBucketLifecycleOutput.add_member(:rules, Shapes::ShapeRef.new(shape: Rules, location_name: "Rule"))
    GetBucketLifecycleOutput.struct_class = Types::GetBucketLifecycleOutput

    GetBucketLifecycleRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketLifecycleRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketLifecycleRequest.struct_class = Types::GetBucketLifecycleRequest

    GetBucketLocationOutput.add_member(:location_constraint, Shapes::ShapeRef.new(shape: BucketLocationConstraint, location_name: "LocationConstraint"))
    GetBucketLocationOutput.struct_class = Types::GetBucketLocationOutput

    GetBucketLocationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketLocationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketLocationRequest.struct_class = Types::GetBucketLocationRequest

    GetBucketLoggingOutput.add_member(:logging_enabled, Shapes::ShapeRef.new(shape: LoggingEnabled, location_name: "LoggingEnabled"))
    GetBucketLoggingOutput.struct_class = Types::GetBucketLoggingOutput

    GetBucketLoggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketLoggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketLoggingRequest.struct_class = Types::GetBucketLoggingRequest

    GetBucketMetricsConfigurationOutput.add_member(:metrics_configuration, Shapes::ShapeRef.new(shape: MetricsConfiguration, location_name: "MetricsConfiguration"))
    GetBucketMetricsConfigurationOutput.struct_class = Types::GetBucketMetricsConfigurationOutput
    GetBucketMetricsConfigurationOutput[:payload] = :metrics_configuration
    GetBucketMetricsConfigurationOutput[:payload_member] = GetBucketMetricsConfigurationOutput.member(:metrics_configuration)

    GetBucketMetricsConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketMetricsConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: MetricsId, required: true, location: "querystring", location_name: "id"))
    GetBucketMetricsConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketMetricsConfigurationRequest.struct_class = Types::GetBucketMetricsConfigurationRequest

    GetBucketNotificationConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketNotificationConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketNotificationConfigurationRequest.struct_class = Types::GetBucketNotificationConfigurationRequest

    GetBucketOwnershipControlsOutput.add_member(:ownership_controls, Shapes::ShapeRef.new(shape: OwnershipControls, location_name: "OwnershipControls"))
    GetBucketOwnershipControlsOutput.struct_class = Types::GetBucketOwnershipControlsOutput
    GetBucketOwnershipControlsOutput[:payload] = :ownership_controls
    GetBucketOwnershipControlsOutput[:payload_member] = GetBucketOwnershipControlsOutput.member(:ownership_controls)

    GetBucketOwnershipControlsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketOwnershipControlsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketOwnershipControlsRequest.struct_class = Types::GetBucketOwnershipControlsRequest

    GetBucketPolicyOutput.add_member(:policy, Shapes::ShapeRef.new(shape: Policy, location_name: "Policy"))
    GetBucketPolicyOutput.struct_class = Types::GetBucketPolicyOutput
    GetBucketPolicyOutput[:payload] = :policy
    GetBucketPolicyOutput[:payload_member] = GetBucketPolicyOutput.member(:policy)

    GetBucketPolicyRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketPolicyRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketPolicyRequest.struct_class = Types::GetBucketPolicyRequest

    GetBucketPolicyStatusOutput.add_member(:policy_status, Shapes::ShapeRef.new(shape: PolicyStatus, location_name: "PolicyStatus"))
    GetBucketPolicyStatusOutput.struct_class = Types::GetBucketPolicyStatusOutput
    GetBucketPolicyStatusOutput[:payload] = :policy_status
    GetBucketPolicyStatusOutput[:payload_member] = GetBucketPolicyStatusOutput.member(:policy_status)

    GetBucketPolicyStatusRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketPolicyStatusRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketPolicyStatusRequest.struct_class = Types::GetBucketPolicyStatusRequest

    GetBucketReplicationOutput.add_member(:replication_configuration, Shapes::ShapeRef.new(shape: ReplicationConfiguration, location_name: "ReplicationConfiguration"))
    GetBucketReplicationOutput.struct_class = Types::GetBucketReplicationOutput
    GetBucketReplicationOutput[:payload] = :replication_configuration
    GetBucketReplicationOutput[:payload_member] = GetBucketReplicationOutput.member(:replication_configuration)

    GetBucketReplicationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketReplicationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketReplicationRequest.struct_class = Types::GetBucketReplicationRequest

    GetBucketRequestPaymentOutput.add_member(:payer, Shapes::ShapeRef.new(shape: Payer, location_name: "Payer"))
    GetBucketRequestPaymentOutput.struct_class = Types::GetBucketRequestPaymentOutput

    GetBucketRequestPaymentRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketRequestPaymentRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketRequestPaymentRequest.struct_class = Types::GetBucketRequestPaymentRequest

    GetBucketTaggingOutput.add_member(:tag_set, Shapes::ShapeRef.new(shape: TagSet, required: true, location_name: "TagSet"))
    GetBucketTaggingOutput.struct_class = Types::GetBucketTaggingOutput

    GetBucketTaggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketTaggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketTaggingRequest.struct_class = Types::GetBucketTaggingRequest

    GetBucketVersioningOutput.add_member(:status, Shapes::ShapeRef.new(shape: BucketVersioningStatus, location_name: "Status"))
    GetBucketVersioningOutput.add_member(:mfa_delete, Shapes::ShapeRef.new(shape: MFADeleteStatus, location_name: "MfaDelete"))
    GetBucketVersioningOutput.struct_class = Types::GetBucketVersioningOutput

    GetBucketVersioningRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketVersioningRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketVersioningRequest.struct_class = Types::GetBucketVersioningRequest

    GetBucketWebsiteOutput.add_member(:redirect_all_requests_to, Shapes::ShapeRef.new(shape: RedirectAllRequestsTo, location_name: "RedirectAllRequestsTo"))
    GetBucketWebsiteOutput.add_member(:index_document, Shapes::ShapeRef.new(shape: IndexDocument, location_name: "IndexDocument"))
    GetBucketWebsiteOutput.add_member(:error_document, Shapes::ShapeRef.new(shape: ErrorDocument, location_name: "ErrorDocument"))
    GetBucketWebsiteOutput.add_member(:routing_rules, Shapes::ShapeRef.new(shape: RoutingRules, location_name: "RoutingRules"))
    GetBucketWebsiteOutput.struct_class = Types::GetBucketWebsiteOutput

    GetBucketWebsiteRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetBucketWebsiteRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetBucketWebsiteRequest.struct_class = Types::GetBucketWebsiteRequest

    GetObjectAclOutput.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    GetObjectAclOutput.add_member(:grants, Shapes::ShapeRef.new(shape: Grants, location_name: "AccessControlList"))
    GetObjectAclOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    GetObjectAclOutput.struct_class = Types::GetObjectAclOutput

    GetObjectAclRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectAclRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectAclRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    GetObjectAclRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectAclRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectAclRequest.struct_class = Types::GetObjectAclRequest

    GetObjectAttributesOutput.add_member(:delete_marker, Shapes::ShapeRef.new(shape: DeleteMarker, location: "header", location_name: "x-amz-delete-marker"))
    GetObjectAttributesOutput.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location: "header", location_name: "Last-Modified"))
    GetObjectAttributesOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    GetObjectAttributesOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    GetObjectAttributesOutput.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    GetObjectAttributesOutput.add_member(:checksum, Shapes::ShapeRef.new(shape: Checksum, location_name: "Checksum"))
    GetObjectAttributesOutput.add_member(:object_parts, Shapes::ShapeRef.new(shape: GetObjectAttributesParts, location_name: "ObjectParts"))
    GetObjectAttributesOutput.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location_name: "StorageClass"))
    GetObjectAttributesOutput.add_member(:object_size, Shapes::ShapeRef.new(shape: ObjectSize, location_name: "ObjectSize"))
    GetObjectAttributesOutput.struct_class = Types::GetObjectAttributesOutput

    GetObjectAttributesParts.add_member(:total_parts_count, Shapes::ShapeRef.new(shape: PartsCount, location_name: "PartsCount"))
    GetObjectAttributesParts.add_member(:part_number_marker, Shapes::ShapeRef.new(shape: PartNumberMarker, location_name: "PartNumberMarker"))
    GetObjectAttributesParts.add_member(:next_part_number_marker, Shapes::ShapeRef.new(shape: NextPartNumberMarker, location_name: "NextPartNumberMarker"))
    GetObjectAttributesParts.add_member(:max_parts, Shapes::ShapeRef.new(shape: MaxParts, location_name: "MaxParts"))
    GetObjectAttributesParts.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    GetObjectAttributesParts.add_member(:parts, Shapes::ShapeRef.new(shape: PartsList, location_name: "Part"))
    GetObjectAttributesParts.struct_class = Types::GetObjectAttributesParts

    GetObjectAttributesRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectAttributesRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectAttributesRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    GetObjectAttributesRequest.add_member(:max_parts, Shapes::ShapeRef.new(shape: MaxParts, location: "header", location_name: "x-amz-max-parts"))
    GetObjectAttributesRequest.add_member(:part_number_marker, Shapes::ShapeRef.new(shape: PartNumberMarker, location: "header", location_name: "x-amz-part-number-marker"))
    GetObjectAttributesRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    GetObjectAttributesRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    GetObjectAttributesRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    GetObjectAttributesRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectAttributesRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectAttributesRequest.add_member(:object_attributes, Shapes::ShapeRef.new(shape: ObjectAttributesList, required: true, location: "header", location_name: "x-amz-object-attributes"))
    GetObjectAttributesRequest.struct_class = Types::GetObjectAttributesRequest

    GetObjectLegalHoldOutput.add_member(:legal_hold, Shapes::ShapeRef.new(shape: ObjectLockLegalHold, location_name: "LegalHold"))
    GetObjectLegalHoldOutput.struct_class = Types::GetObjectLegalHoldOutput
    GetObjectLegalHoldOutput[:payload] = :legal_hold
    GetObjectLegalHoldOutput[:payload_member] = GetObjectLegalHoldOutput.member(:legal_hold)

    GetObjectLegalHoldRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectLegalHoldRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectLegalHoldRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    GetObjectLegalHoldRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectLegalHoldRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectLegalHoldRequest.struct_class = Types::GetObjectLegalHoldRequest

    GetObjectLockConfigurationOutput.add_member(:object_lock_configuration, Shapes::ShapeRef.new(shape: ObjectLockConfiguration, location_name: "ObjectLockConfiguration"))
    GetObjectLockConfigurationOutput.struct_class = Types::GetObjectLockConfigurationOutput
    GetObjectLockConfigurationOutput[:payload] = :object_lock_configuration
    GetObjectLockConfigurationOutput[:payload_member] = GetObjectLockConfigurationOutput.member(:object_lock_configuration)

    GetObjectLockConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectLockConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectLockConfigurationRequest.struct_class = Types::GetObjectLockConfigurationRequest

    GetObjectOutput.add_member(:body, Shapes::ShapeRef.new(shape: Body, location_name: "Body", metadata: {"streaming"=>true}))
    GetObjectOutput.add_member(:delete_marker, Shapes::ShapeRef.new(shape: DeleteMarker, location: "header", location_name: "x-amz-delete-marker"))
    GetObjectOutput.add_member(:accept_ranges, Shapes::ShapeRef.new(shape: AcceptRanges, location: "header", location_name: "accept-ranges"))
    GetObjectOutput.add_member(:expiration, Shapes::ShapeRef.new(shape: Expiration, location: "header", location_name: "x-amz-expiration"))
    GetObjectOutput.add_member(:restore, Shapes::ShapeRef.new(shape: Restore, location: "header", location_name: "x-amz-restore"))
    GetObjectOutput.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location: "header", location_name: "Last-Modified"))
    GetObjectOutput.add_member(:content_length, Shapes::ShapeRef.new(shape: ContentLength, location: "header", location_name: "Content-Length"))
    GetObjectOutput.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location: "header", location_name: "ETag"))
    GetObjectOutput.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    GetObjectOutput.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    GetObjectOutput.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    GetObjectOutput.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    GetObjectOutput.add_member(:missing_meta, Shapes::ShapeRef.new(shape: MissingMeta, location: "header", location_name: "x-amz-missing-meta"))
    GetObjectOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    GetObjectOutput.add_member(:cache_control, Shapes::ShapeRef.new(shape: CacheControl, location: "header", location_name: "Cache-Control"))
    GetObjectOutput.add_member(:content_disposition, Shapes::ShapeRef.new(shape: ContentDisposition, location: "header", location_name: "Content-Disposition"))
    GetObjectOutput.add_member(:content_encoding, Shapes::ShapeRef.new(shape: ContentEncoding, location: "header", location_name: "Content-Encoding"))
    GetObjectOutput.add_member(:content_language, Shapes::ShapeRef.new(shape: ContentLanguage, location: "header", location_name: "Content-Language"))
    GetObjectOutput.add_member(:content_range, Shapes::ShapeRef.new(shape: ContentRange, location: "header", location_name: "Content-Range"))
    GetObjectOutput.add_member(:content_type, Shapes::ShapeRef.new(shape: ContentType, location: "header", location_name: "Content-Type"))
    GetObjectOutput.add_member(:expires, Shapes::ShapeRef.new(shape: Expires, location: "header", location_name: "Expires"))
    GetObjectOutput.add_member(:expires_string, Shapes::ShapeRef.new(shape: ExpiresString, location: "header", location_name: "Expires"))
    GetObjectOutput.add_member(:website_redirect_location, Shapes::ShapeRef.new(shape: WebsiteRedirectLocation, location: "header", location_name: "x-amz-website-redirect-location"))
    GetObjectOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    GetObjectOutput.add_member(:metadata, Shapes::ShapeRef.new(shape: Metadata, location: "headers", location_name: "x-amz-meta-"))
    GetObjectOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    GetObjectOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    GetObjectOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    GetObjectOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    GetObjectOutput.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location: "header", location_name: "x-amz-storage-class"))
    GetObjectOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    GetObjectOutput.add_member(:replication_status, Shapes::ShapeRef.new(shape: ReplicationStatus, location: "header", location_name: "x-amz-replication-status"))
    GetObjectOutput.add_member(:parts_count, Shapes::ShapeRef.new(shape: PartsCount, location: "header", location_name: "x-amz-mp-parts-count"))
    GetObjectOutput.add_member(:tag_count, Shapes::ShapeRef.new(shape: TagCount, location: "header", location_name: "x-amz-tagging-count"))
    GetObjectOutput.add_member(:object_lock_mode, Shapes::ShapeRef.new(shape: ObjectLockMode, location: "header", location_name: "x-amz-object-lock-mode"))
    GetObjectOutput.add_member(:object_lock_retain_until_date, Shapes::ShapeRef.new(shape: ObjectLockRetainUntilDate, location: "header", location_name: "x-amz-object-lock-retain-until-date"))
    GetObjectOutput.add_member(:object_lock_legal_hold_status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location: "header", location_name: "x-amz-object-lock-legal-hold"))
    GetObjectOutput.struct_class = Types::GetObjectOutput
    GetObjectOutput[:payload] = :body
    GetObjectOutput[:payload_member] = GetObjectOutput.member(:body)

    GetObjectRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectRequest.add_member(:if_match, Shapes::ShapeRef.new(shape: IfMatch, location: "header", location_name: "If-Match"))
    GetObjectRequest.add_member(:if_modified_since, Shapes::ShapeRef.new(shape: IfModifiedSince, location: "header", location_name: "If-Modified-Since"))
    GetObjectRequest.add_member(:if_none_match, Shapes::ShapeRef.new(shape: IfNoneMatch, location: "header", location_name: "If-None-Match"))
    GetObjectRequest.add_member(:if_unmodified_since, Shapes::ShapeRef.new(shape: IfUnmodifiedSince, location: "header", location_name: "If-Unmodified-Since"))
    GetObjectRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectRequest.add_member(:range, Shapes::ShapeRef.new(shape: Range, location: "header", location_name: "Range"))
    GetObjectRequest.add_member(:response_cache_control, Shapes::ShapeRef.new(shape: ResponseCacheControl, location: "querystring", location_name: "response-cache-control"))
    GetObjectRequest.add_member(:response_content_disposition, Shapes::ShapeRef.new(shape: ResponseContentDisposition, location: "querystring", location_name: "response-content-disposition"))
    GetObjectRequest.add_member(:response_content_encoding, Shapes::ShapeRef.new(shape: ResponseContentEncoding, location: "querystring", location_name: "response-content-encoding"))
    GetObjectRequest.add_member(:response_content_language, Shapes::ShapeRef.new(shape: ResponseContentLanguage, location: "querystring", location_name: "response-content-language"))
    GetObjectRequest.add_member(:response_content_type, Shapes::ShapeRef.new(shape: ResponseContentType, location: "querystring", location_name: "response-content-type"))
    GetObjectRequest.add_member(:response_expires, Shapes::ShapeRef.new(shape: ResponseExpires, location: "querystring", location_name: "response-expires"))
    GetObjectRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    GetObjectRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    GetObjectRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    GetObjectRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    GetObjectRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectRequest.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, location: "querystring", location_name: "partNumber"))
    GetObjectRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectRequest.add_member(:checksum_mode, Shapes::ShapeRef.new(shape: ChecksumMode, location: "header", location_name: "x-amz-checksum-mode"))
    GetObjectRequest.struct_class = Types::GetObjectRequest

    GetObjectRetentionOutput.add_member(:retention, Shapes::ShapeRef.new(shape: ObjectLockRetention, location_name: "Retention"))
    GetObjectRetentionOutput.struct_class = Types::GetObjectRetentionOutput
    GetObjectRetentionOutput[:payload] = :retention
    GetObjectRetentionOutput[:payload_member] = GetObjectRetentionOutput.member(:retention)

    GetObjectRetentionRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectRetentionRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectRetentionRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    GetObjectRetentionRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectRetentionRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectRetentionRequest.struct_class = Types::GetObjectRetentionRequest

    GetObjectTaggingOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    GetObjectTaggingOutput.add_member(:tag_set, Shapes::ShapeRef.new(shape: TagSet, required: true, location_name: "TagSet"))
    GetObjectTaggingOutput.struct_class = Types::GetObjectTaggingOutput

    GetObjectTaggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectTaggingRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectTaggingRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    GetObjectTaggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectTaggingRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectTaggingRequest.struct_class = Types::GetObjectTaggingRequest

    GetObjectTorrentOutput.add_member(:body, Shapes::ShapeRef.new(shape: Body, location_name: "Body", metadata: {"streaming"=>true}))
    GetObjectTorrentOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    GetObjectTorrentOutput.struct_class = Types::GetObjectTorrentOutput
    GetObjectTorrentOutput[:payload] = :body
    GetObjectTorrentOutput[:payload_member] = GetObjectTorrentOutput.member(:body)

    GetObjectTorrentRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetObjectTorrentRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    GetObjectTorrentRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    GetObjectTorrentRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetObjectTorrentRequest.struct_class = Types::GetObjectTorrentRequest

    GetPublicAccessBlockOutput.add_member(:public_access_block_configuration, Shapes::ShapeRef.new(shape: PublicAccessBlockConfiguration, location_name: "PublicAccessBlockConfiguration"))
    GetPublicAccessBlockOutput.struct_class = Types::GetPublicAccessBlockOutput
    GetPublicAccessBlockOutput[:payload] = :public_access_block_configuration
    GetPublicAccessBlockOutput[:payload_member] = GetPublicAccessBlockOutput.member(:public_access_block_configuration)

    GetPublicAccessBlockRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    GetPublicAccessBlockRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    GetPublicAccessBlockRequest.struct_class = Types::GetPublicAccessBlockRequest

    GlacierJobParameters.add_member(:tier, Shapes::ShapeRef.new(shape: Tier, required: true, location_name: "Tier"))
    GlacierJobParameters.struct_class = Types::GlacierJobParameters

    Grant.add_member(:grantee, Shapes::ShapeRef.new(shape: Grantee, location_name: "Grantee"))
    Grant.add_member(:permission, Shapes::ShapeRef.new(shape: Permission, location_name: "Permission"))
    Grant.struct_class = Types::Grant

    Grantee.add_member(:display_name, Shapes::ShapeRef.new(shape: DisplayName, location_name: "DisplayName"))
    Grantee.add_member(:email_address, Shapes::ShapeRef.new(shape: EmailAddress, location_name: "EmailAddress"))
    Grantee.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    Grantee.add_member(:type, Shapes::ShapeRef.new(shape: Type, required: true, location_name: "xsi:type", metadata: {"xmlAttribute"=>true}))
    Grantee.add_member(:uri, Shapes::ShapeRef.new(shape: URI, location_name: "URI"))
    Grantee.struct_class = Types::Grantee

    Grants.member = Shapes::ShapeRef.new(shape: Grant, location_name: "Grant")

    HeadBucketRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    HeadBucketRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    HeadBucketRequest.struct_class = Types::HeadBucketRequest

    HeadObjectOutput.add_member(:delete_marker, Shapes::ShapeRef.new(shape: DeleteMarker, location: "header", location_name: "x-amz-delete-marker"))
    HeadObjectOutput.add_member(:accept_ranges, Shapes::ShapeRef.new(shape: AcceptRanges, location: "header", location_name: "accept-ranges"))
    HeadObjectOutput.add_member(:expiration, Shapes::ShapeRef.new(shape: Expiration, location: "header", location_name: "x-amz-expiration"))
    HeadObjectOutput.add_member(:restore, Shapes::ShapeRef.new(shape: Restore, location: "header", location_name: "x-amz-restore"))
    HeadObjectOutput.add_member(:archive_status, Shapes::ShapeRef.new(shape: ArchiveStatus, location: "header", location_name: "x-amz-archive-status"))
    HeadObjectOutput.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location: "header", location_name: "Last-Modified"))
    HeadObjectOutput.add_member(:content_length, Shapes::ShapeRef.new(shape: ContentLength, location: "header", location_name: "Content-Length"))
    HeadObjectOutput.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    HeadObjectOutput.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    HeadObjectOutput.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    HeadObjectOutput.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    HeadObjectOutput.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location: "header", location_name: "ETag"))
    HeadObjectOutput.add_member(:missing_meta, Shapes::ShapeRef.new(shape: MissingMeta, location: "header", location_name: "x-amz-missing-meta"))
    HeadObjectOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    HeadObjectOutput.add_member(:cache_control, Shapes::ShapeRef.new(shape: CacheControl, location: "header", location_name: "Cache-Control"))
    HeadObjectOutput.add_member(:content_disposition, Shapes::ShapeRef.new(shape: ContentDisposition, location: "header", location_name: "Content-Disposition"))
    HeadObjectOutput.add_member(:content_encoding, Shapes::ShapeRef.new(shape: ContentEncoding, location: "header", location_name: "Content-Encoding"))
    HeadObjectOutput.add_member(:content_language, Shapes::ShapeRef.new(shape: ContentLanguage, location: "header", location_name: "Content-Language"))
    HeadObjectOutput.add_member(:content_type, Shapes::ShapeRef.new(shape: ContentType, location: "header", location_name: "Content-Type"))
    HeadObjectOutput.add_member(:expires, Shapes::ShapeRef.new(shape: Expires, location: "header", location_name: "Expires"))
    HeadObjectOutput.add_member(:expires_string, Shapes::ShapeRef.new(shape: ExpiresString, location: "header", location_name: "Expires"))
    HeadObjectOutput.add_member(:website_redirect_location, Shapes::ShapeRef.new(shape: WebsiteRedirectLocation, location: "header", location_name: "x-amz-website-redirect-location"))
    HeadObjectOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    HeadObjectOutput.add_member(:metadata, Shapes::ShapeRef.new(shape: Metadata, location: "headers", location_name: "x-amz-meta-"))
    HeadObjectOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    HeadObjectOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    HeadObjectOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    HeadObjectOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    HeadObjectOutput.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location: "header", location_name: "x-amz-storage-class"))
    HeadObjectOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    HeadObjectOutput.add_member(:replication_status, Shapes::ShapeRef.new(shape: ReplicationStatus, location: "header", location_name: "x-amz-replication-status"))
    HeadObjectOutput.add_member(:parts_count, Shapes::ShapeRef.new(shape: PartsCount, location: "header", location_name: "x-amz-mp-parts-count"))
    HeadObjectOutput.add_member(:object_lock_mode, Shapes::ShapeRef.new(shape: ObjectLockMode, location: "header", location_name: "x-amz-object-lock-mode"))
    HeadObjectOutput.add_member(:object_lock_retain_until_date, Shapes::ShapeRef.new(shape: ObjectLockRetainUntilDate, location: "header", location_name: "x-amz-object-lock-retain-until-date"))
    HeadObjectOutput.add_member(:object_lock_legal_hold_status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location: "header", location_name: "x-amz-object-lock-legal-hold"))
    HeadObjectOutput.struct_class = Types::HeadObjectOutput

    HeadObjectRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    HeadObjectRequest.add_member(:if_match, Shapes::ShapeRef.new(shape: IfMatch, location: "header", location_name: "If-Match"))
    HeadObjectRequest.add_member(:if_modified_since, Shapes::ShapeRef.new(shape: IfModifiedSince, location: "header", location_name: "If-Modified-Since"))
    HeadObjectRequest.add_member(:if_none_match, Shapes::ShapeRef.new(shape: IfNoneMatch, location: "header", location_name: "If-None-Match"))
    HeadObjectRequest.add_member(:if_unmodified_since, Shapes::ShapeRef.new(shape: IfUnmodifiedSince, location: "header", location_name: "If-Unmodified-Since"))
    HeadObjectRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    HeadObjectRequest.add_member(:range, Shapes::ShapeRef.new(shape: Range, location: "header", location_name: "Range"))
    HeadObjectRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    HeadObjectRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    HeadObjectRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    HeadObjectRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    HeadObjectRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    HeadObjectRequest.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, location: "querystring", location_name: "partNumber"))
    HeadObjectRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    HeadObjectRequest.add_member(:checksum_mode, Shapes::ShapeRef.new(shape: ChecksumMode, location: "header", location_name: "x-amz-checksum-mode"))
    HeadObjectRequest.struct_class = Types::HeadObjectRequest

    IndexDocument.add_member(:suffix, Shapes::ShapeRef.new(shape: Suffix, required: true, location_name: "Suffix"))
    IndexDocument.struct_class = Types::IndexDocument

    Initiator.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    Initiator.add_member(:display_name, Shapes::ShapeRef.new(shape: DisplayName, location_name: "DisplayName"))
    Initiator.struct_class = Types::Initiator

    InputSerialization.add_member(:csv, Shapes::ShapeRef.new(shape: CSVInput, location_name: "CSV"))
    InputSerialization.add_member(:compression_type, Shapes::ShapeRef.new(shape: CompressionType, location_name: "CompressionType"))
    InputSerialization.add_member(:json, Shapes::ShapeRef.new(shape: JSONInput, location_name: "JSON"))
    InputSerialization.add_member(:parquet, Shapes::ShapeRef.new(shape: ParquetInput, location_name: "Parquet"))
    InputSerialization.struct_class = Types::InputSerialization

    IntelligentTieringAndOperator.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    IntelligentTieringAndOperator.add_member(:tags, Shapes::ShapeRef.new(shape: TagSet, location_name: "Tag", metadata: {"flattened"=>true}))
    IntelligentTieringAndOperator.struct_class = Types::IntelligentTieringAndOperator

    IntelligentTieringConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: IntelligentTieringId, required: true, location_name: "Id"))
    IntelligentTieringConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: IntelligentTieringFilter, location_name: "Filter"))
    IntelligentTieringConfiguration.add_member(:status, Shapes::ShapeRef.new(shape: IntelligentTieringStatus, required: true, location_name: "Status"))
    IntelligentTieringConfiguration.add_member(:tierings, Shapes::ShapeRef.new(shape: TieringList, required: true, location_name: "Tiering"))
    IntelligentTieringConfiguration.struct_class = Types::IntelligentTieringConfiguration

    IntelligentTieringConfigurationList.member = Shapes::ShapeRef.new(shape: IntelligentTieringConfiguration)

    IntelligentTieringFilter.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    IntelligentTieringFilter.add_member(:tag, Shapes::ShapeRef.new(shape: Tag, location_name: "Tag"))
    IntelligentTieringFilter.add_member(:and, Shapes::ShapeRef.new(shape: IntelligentTieringAndOperator, location_name: "And"))
    IntelligentTieringFilter.struct_class = Types::IntelligentTieringFilter

    InvalidObjectState.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location_name: "StorageClass"))
    InvalidObjectState.add_member(:access_tier, Shapes::ShapeRef.new(shape: IntelligentTieringAccessTier, location_name: "AccessTier"))
    InvalidObjectState.struct_class = Types::InvalidObjectState

    InventoryConfiguration.add_member(:destination, Shapes::ShapeRef.new(shape: InventoryDestination, required: true, location_name: "Destination"))
    InventoryConfiguration.add_member(:is_enabled, Shapes::ShapeRef.new(shape: IsEnabled, required: true, location_name: "IsEnabled"))
    InventoryConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: InventoryFilter, location_name: "Filter"))
    InventoryConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: InventoryId, required: true, location_name: "Id"))
    InventoryConfiguration.add_member(:included_object_versions, Shapes::ShapeRef.new(shape: InventoryIncludedObjectVersions, required: true, location_name: "IncludedObjectVersions"))
    InventoryConfiguration.add_member(:optional_fields, Shapes::ShapeRef.new(shape: InventoryOptionalFields, location_name: "OptionalFields"))
    InventoryConfiguration.add_member(:schedule, Shapes::ShapeRef.new(shape: InventorySchedule, required: true, location_name: "Schedule"))
    InventoryConfiguration.struct_class = Types::InventoryConfiguration

    InventoryConfigurationList.member = Shapes::ShapeRef.new(shape: InventoryConfiguration)

    InventoryDestination.add_member(:s3_bucket_destination, Shapes::ShapeRef.new(shape: InventoryS3BucketDestination, required: true, location_name: "S3BucketDestination"))
    InventoryDestination.struct_class = Types::InventoryDestination

    InventoryEncryption.add_member(:sses3, Shapes::ShapeRef.new(shape: SSES3, location_name: "SSE-S3"))
    InventoryEncryption.add_member(:ssekms, Shapes::ShapeRef.new(shape: SSEKMS, location_name: "SSE-KMS"))
    InventoryEncryption.struct_class = Types::InventoryEncryption

    InventoryFilter.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, required: true, location_name: "Prefix"))
    InventoryFilter.struct_class = Types::InventoryFilter

    InventoryOptionalFields.member = Shapes::ShapeRef.new(shape: InventoryOptionalField, location_name: "Field")

    InventoryS3BucketDestination.add_member(:account_id, Shapes::ShapeRef.new(shape: AccountId, location_name: "AccountId"))
    InventoryS3BucketDestination.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location_name: "Bucket"))
    InventoryS3BucketDestination.add_member(:format, Shapes::ShapeRef.new(shape: InventoryFormat, required: true, location_name: "Format"))
    InventoryS3BucketDestination.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    InventoryS3BucketDestination.add_member(:encryption, Shapes::ShapeRef.new(shape: InventoryEncryption, location_name: "Encryption"))
    InventoryS3BucketDestination.struct_class = Types::InventoryS3BucketDestination

    InventorySchedule.add_member(:frequency, Shapes::ShapeRef.new(shape: InventoryFrequency, required: true, location_name: "Frequency"))
    InventorySchedule.struct_class = Types::InventorySchedule

    JSONInput.add_member(:type, Shapes::ShapeRef.new(shape: JSONType, location_name: "Type"))
    JSONInput.struct_class = Types::JSONInput

    JSONOutput.add_member(:record_delimiter, Shapes::ShapeRef.new(shape: RecordDelimiter, location_name: "RecordDelimiter"))
    JSONOutput.struct_class = Types::JSONOutput

    LambdaFunctionConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: NotificationId, location_name: "Id"))
    LambdaFunctionConfiguration.add_member(:lambda_function_arn, Shapes::ShapeRef.new(shape: LambdaFunctionArn, required: true, location_name: "CloudFunction"))
    LambdaFunctionConfiguration.add_member(:events, Shapes::ShapeRef.new(shape: EventList, required: true, location_name: "Event"))
    LambdaFunctionConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: NotificationConfigurationFilter, location_name: "Filter"))
    LambdaFunctionConfiguration.struct_class = Types::LambdaFunctionConfiguration

    LambdaFunctionConfigurationList.member = Shapes::ShapeRef.new(shape: LambdaFunctionConfiguration)

    LifecycleConfiguration.add_member(:rules, Shapes::ShapeRef.new(shape: Rules, required: true, location_name: "Rule"))
    LifecycleConfiguration.struct_class = Types::LifecycleConfiguration

    LifecycleExpiration.add_member(:date, Shapes::ShapeRef.new(shape: Date, location_name: "Date"))
    LifecycleExpiration.add_member(:days, Shapes::ShapeRef.new(shape: Days, location_name: "Days"))
    LifecycleExpiration.add_member(:expired_object_delete_marker, Shapes::ShapeRef.new(shape: ExpiredObjectDeleteMarker, location_name: "ExpiredObjectDeleteMarker"))
    LifecycleExpiration.struct_class = Types::LifecycleExpiration

    LifecycleRule.add_member(:expiration, Shapes::ShapeRef.new(shape: LifecycleExpiration, location_name: "Expiration"))
    LifecycleRule.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    LifecycleRule.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, deprecated: true, location_name: "Prefix"))
    LifecycleRule.add_member(:filter, Shapes::ShapeRef.new(shape: LifecycleRuleFilter, location_name: "Filter"))
    LifecycleRule.add_member(:status, Shapes::ShapeRef.new(shape: ExpirationStatus, required: true, location_name: "Status"))
    LifecycleRule.add_member(:transitions, Shapes::ShapeRef.new(shape: TransitionList, location_name: "Transition"))
    LifecycleRule.add_member(:noncurrent_version_transitions, Shapes::ShapeRef.new(shape: NoncurrentVersionTransitionList, location_name: "NoncurrentVersionTransition"))
    LifecycleRule.add_member(:noncurrent_version_expiration, Shapes::ShapeRef.new(shape: NoncurrentVersionExpiration, location_name: "NoncurrentVersionExpiration"))
    LifecycleRule.add_member(:abort_incomplete_multipart_upload, Shapes::ShapeRef.new(shape: AbortIncompleteMultipartUpload, location_name: "AbortIncompleteMultipartUpload"))
    LifecycleRule.struct_class = Types::LifecycleRule

    LifecycleRuleAndOperator.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    LifecycleRuleAndOperator.add_member(:tags, Shapes::ShapeRef.new(shape: TagSet, location_name: "Tag", metadata: {"flattened"=>true}))
    LifecycleRuleAndOperator.add_member(:object_size_greater_than, Shapes::ShapeRef.new(shape: ObjectSizeGreaterThanBytes, location_name: "ObjectSizeGreaterThan"))
    LifecycleRuleAndOperator.add_member(:object_size_less_than, Shapes::ShapeRef.new(shape: ObjectSizeLessThanBytes, location_name: "ObjectSizeLessThan"))
    LifecycleRuleAndOperator.struct_class = Types::LifecycleRuleAndOperator

    LifecycleRuleFilter.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    LifecycleRuleFilter.add_member(:tag, Shapes::ShapeRef.new(shape: Tag, location_name: "Tag"))
    LifecycleRuleFilter.add_member(:object_size_greater_than, Shapes::ShapeRef.new(shape: ObjectSizeGreaterThanBytes, location_name: "ObjectSizeGreaterThan"))
    LifecycleRuleFilter.add_member(:object_size_less_than, Shapes::ShapeRef.new(shape: ObjectSizeLessThanBytes, location_name: "ObjectSizeLessThan"))
    LifecycleRuleFilter.add_member(:and, Shapes::ShapeRef.new(shape: LifecycleRuleAndOperator, location_name: "And"))
    LifecycleRuleFilter.struct_class = Types::LifecycleRuleFilter

    LifecycleRules.member = Shapes::ShapeRef.new(shape: LifecycleRule)

    ListBucketAnalyticsConfigurationsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListBucketAnalyticsConfigurationsOutput.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location_name: "ContinuationToken"))
    ListBucketAnalyticsConfigurationsOutput.add_member(:next_continuation_token, Shapes::ShapeRef.new(shape: NextToken, location_name: "NextContinuationToken"))
    ListBucketAnalyticsConfigurationsOutput.add_member(:analytics_configuration_list, Shapes::ShapeRef.new(shape: AnalyticsConfigurationList, location_name: "AnalyticsConfiguration"))
    ListBucketAnalyticsConfigurationsOutput.struct_class = Types::ListBucketAnalyticsConfigurationsOutput

    ListBucketAnalyticsConfigurationsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListBucketAnalyticsConfigurationsRequest.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location: "querystring", location_name: "continuation-token"))
    ListBucketAnalyticsConfigurationsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListBucketAnalyticsConfigurationsRequest.struct_class = Types::ListBucketAnalyticsConfigurationsRequest

    ListBucketIntelligentTieringConfigurationsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListBucketIntelligentTieringConfigurationsOutput.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location_name: "ContinuationToken"))
    ListBucketIntelligentTieringConfigurationsOutput.add_member(:next_continuation_token, Shapes::ShapeRef.new(shape: NextToken, location_name: "NextContinuationToken"))
    ListBucketIntelligentTieringConfigurationsOutput.add_member(:intelligent_tiering_configuration_list, Shapes::ShapeRef.new(shape: IntelligentTieringConfigurationList, location_name: "IntelligentTieringConfiguration"))
    ListBucketIntelligentTieringConfigurationsOutput.struct_class = Types::ListBucketIntelligentTieringConfigurationsOutput

    ListBucketIntelligentTieringConfigurationsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListBucketIntelligentTieringConfigurationsRequest.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location: "querystring", location_name: "continuation-token"))
    ListBucketIntelligentTieringConfigurationsRequest.struct_class = Types::ListBucketIntelligentTieringConfigurationsRequest

    ListBucketInventoryConfigurationsOutput.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location_name: "ContinuationToken"))
    ListBucketInventoryConfigurationsOutput.add_member(:inventory_configuration_list, Shapes::ShapeRef.new(shape: InventoryConfigurationList, location_name: "InventoryConfiguration"))
    ListBucketInventoryConfigurationsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListBucketInventoryConfigurationsOutput.add_member(:next_continuation_token, Shapes::ShapeRef.new(shape: NextToken, location_name: "NextContinuationToken"))
    ListBucketInventoryConfigurationsOutput.struct_class = Types::ListBucketInventoryConfigurationsOutput

    ListBucketInventoryConfigurationsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListBucketInventoryConfigurationsRequest.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location: "querystring", location_name: "continuation-token"))
    ListBucketInventoryConfigurationsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListBucketInventoryConfigurationsRequest.struct_class = Types::ListBucketInventoryConfigurationsRequest

    ListBucketMetricsConfigurationsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListBucketMetricsConfigurationsOutput.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location_name: "ContinuationToken"))
    ListBucketMetricsConfigurationsOutput.add_member(:next_continuation_token, Shapes::ShapeRef.new(shape: NextToken, location_name: "NextContinuationToken"))
    ListBucketMetricsConfigurationsOutput.add_member(:metrics_configuration_list, Shapes::ShapeRef.new(shape: MetricsConfigurationList, location_name: "MetricsConfiguration"))
    ListBucketMetricsConfigurationsOutput.struct_class = Types::ListBucketMetricsConfigurationsOutput

    ListBucketMetricsConfigurationsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListBucketMetricsConfigurationsRequest.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location: "querystring", location_name: "continuation-token"))
    ListBucketMetricsConfigurationsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListBucketMetricsConfigurationsRequest.struct_class = Types::ListBucketMetricsConfigurationsRequest

    ListBucketsOutput.add_member(:buckets, Shapes::ShapeRef.new(shape: Buckets, location_name: "Buckets"))
    ListBucketsOutput.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    ListBucketsOutput.struct_class = Types::ListBucketsOutput

    ListMultipartUploadsOutput.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, location_name: "Bucket"))
    ListMultipartUploadsOutput.add_member(:key_marker, Shapes::ShapeRef.new(shape: KeyMarker, location_name: "KeyMarker"))
    ListMultipartUploadsOutput.add_member(:upload_id_marker, Shapes::ShapeRef.new(shape: UploadIdMarker, location_name: "UploadIdMarker"))
    ListMultipartUploadsOutput.add_member(:next_key_marker, Shapes::ShapeRef.new(shape: NextKeyMarker, location_name: "NextKeyMarker"))
    ListMultipartUploadsOutput.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    ListMultipartUploadsOutput.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location_name: "Delimiter"))
    ListMultipartUploadsOutput.add_member(:next_upload_id_marker, Shapes::ShapeRef.new(shape: NextUploadIdMarker, location_name: "NextUploadIdMarker"))
    ListMultipartUploadsOutput.add_member(:max_uploads, Shapes::ShapeRef.new(shape: MaxUploads, location_name: "MaxUploads"))
    ListMultipartUploadsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListMultipartUploadsOutput.add_member(:uploads, Shapes::ShapeRef.new(shape: MultipartUploadList, location_name: "Upload"))
    ListMultipartUploadsOutput.add_member(:common_prefixes, Shapes::ShapeRef.new(shape: CommonPrefixList, location_name: "CommonPrefixes"))
    ListMultipartUploadsOutput.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location_name: "EncodingType"))
    ListMultipartUploadsOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    ListMultipartUploadsOutput.struct_class = Types::ListMultipartUploadsOutput

    ListMultipartUploadsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListMultipartUploadsRequest.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location: "querystring", location_name: "delimiter"))
    ListMultipartUploadsRequest.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location: "querystring", location_name: "encoding-type"))
    ListMultipartUploadsRequest.add_member(:key_marker, Shapes::ShapeRef.new(shape: KeyMarker, location: "querystring", location_name: "key-marker"))
    ListMultipartUploadsRequest.add_member(:max_uploads, Shapes::ShapeRef.new(shape: MaxUploads, location: "querystring", location_name: "max-uploads"))
    ListMultipartUploadsRequest.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location: "querystring", location_name: "prefix"))
    ListMultipartUploadsRequest.add_member(:upload_id_marker, Shapes::ShapeRef.new(shape: UploadIdMarker, location: "querystring", location_name: "upload-id-marker"))
    ListMultipartUploadsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListMultipartUploadsRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    ListMultipartUploadsRequest.struct_class = Types::ListMultipartUploadsRequest

    ListObjectVersionsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListObjectVersionsOutput.add_member(:key_marker, Shapes::ShapeRef.new(shape: KeyMarker, location_name: "KeyMarker"))
    ListObjectVersionsOutput.add_member(:version_id_marker, Shapes::ShapeRef.new(shape: VersionIdMarker, location_name: "VersionIdMarker"))
    ListObjectVersionsOutput.add_member(:next_key_marker, Shapes::ShapeRef.new(shape: NextKeyMarker, location_name: "NextKeyMarker"))
    ListObjectVersionsOutput.add_member(:next_version_id_marker, Shapes::ShapeRef.new(shape: NextVersionIdMarker, location_name: "NextVersionIdMarker"))
    ListObjectVersionsOutput.add_member(:versions, Shapes::ShapeRef.new(shape: ObjectVersionList, location_name: "Version"))
    ListObjectVersionsOutput.add_member(:delete_markers, Shapes::ShapeRef.new(shape: DeleteMarkers, location_name: "DeleteMarker"))
    ListObjectVersionsOutput.add_member(:name, Shapes::ShapeRef.new(shape: BucketName, location_name: "Name"))
    ListObjectVersionsOutput.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    ListObjectVersionsOutput.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location_name: "Delimiter"))
    ListObjectVersionsOutput.add_member(:max_keys, Shapes::ShapeRef.new(shape: MaxKeys, location_name: "MaxKeys"))
    ListObjectVersionsOutput.add_member(:common_prefixes, Shapes::ShapeRef.new(shape: CommonPrefixList, location_name: "CommonPrefixes"))
    ListObjectVersionsOutput.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location_name: "EncodingType"))
    ListObjectVersionsOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    ListObjectVersionsOutput.struct_class = Types::ListObjectVersionsOutput

    ListObjectVersionsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListObjectVersionsRequest.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location: "querystring", location_name: "delimiter"))
    ListObjectVersionsRequest.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location: "querystring", location_name: "encoding-type"))
    ListObjectVersionsRequest.add_member(:key_marker, Shapes::ShapeRef.new(shape: KeyMarker, location: "querystring", location_name: "key-marker"))
    ListObjectVersionsRequest.add_member(:max_keys, Shapes::ShapeRef.new(shape: MaxKeys, location: "querystring", location_name: "max-keys"))
    ListObjectVersionsRequest.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location: "querystring", location_name: "prefix"))
    ListObjectVersionsRequest.add_member(:version_id_marker, Shapes::ShapeRef.new(shape: VersionIdMarker, location: "querystring", location_name: "version-id-marker"))
    ListObjectVersionsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListObjectVersionsRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    ListObjectVersionsRequest.struct_class = Types::ListObjectVersionsRequest

    ListObjectsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListObjectsOutput.add_member(:marker, Shapes::ShapeRef.new(shape: Marker, location_name: "Marker"))
    ListObjectsOutput.add_member(:next_marker, Shapes::ShapeRef.new(shape: NextMarker, location_name: "NextMarker"))
    ListObjectsOutput.add_member(:contents, Shapes::ShapeRef.new(shape: ObjectList, location_name: "Contents"))
    ListObjectsOutput.add_member(:name, Shapes::ShapeRef.new(shape: BucketName, location_name: "Name"))
    ListObjectsOutput.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    ListObjectsOutput.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location_name: "Delimiter"))
    ListObjectsOutput.add_member(:max_keys, Shapes::ShapeRef.new(shape: MaxKeys, location_name: "MaxKeys"))
    ListObjectsOutput.add_member(:common_prefixes, Shapes::ShapeRef.new(shape: CommonPrefixList, location_name: "CommonPrefixes"))
    ListObjectsOutput.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location_name: "EncodingType"))
    ListObjectsOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    ListObjectsOutput.struct_class = Types::ListObjectsOutput

    ListObjectsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListObjectsRequest.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location: "querystring", location_name: "delimiter"))
    ListObjectsRequest.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location: "querystring", location_name: "encoding-type"))
    ListObjectsRequest.add_member(:marker, Shapes::ShapeRef.new(shape: Marker, location: "querystring", location_name: "marker"))
    ListObjectsRequest.add_member(:max_keys, Shapes::ShapeRef.new(shape: MaxKeys, location: "querystring", location_name: "max-keys"))
    ListObjectsRequest.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location: "querystring", location_name: "prefix"))
    ListObjectsRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    ListObjectsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListObjectsRequest.struct_class = Types::ListObjectsRequest

    ListObjectsV2Output.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListObjectsV2Output.add_member(:contents, Shapes::ShapeRef.new(shape: ObjectList, location_name: "Contents"))
    ListObjectsV2Output.add_member(:name, Shapes::ShapeRef.new(shape: BucketName, location_name: "Name"))
    ListObjectsV2Output.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    ListObjectsV2Output.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location_name: "Delimiter"))
    ListObjectsV2Output.add_member(:max_keys, Shapes::ShapeRef.new(shape: MaxKeys, location_name: "MaxKeys"))
    ListObjectsV2Output.add_member(:common_prefixes, Shapes::ShapeRef.new(shape: CommonPrefixList, location_name: "CommonPrefixes"))
    ListObjectsV2Output.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location_name: "EncodingType"))
    ListObjectsV2Output.add_member(:key_count, Shapes::ShapeRef.new(shape: KeyCount, location_name: "KeyCount"))
    ListObjectsV2Output.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location_name: "ContinuationToken"))
    ListObjectsV2Output.add_member(:next_continuation_token, Shapes::ShapeRef.new(shape: NextToken, location_name: "NextContinuationToken"))
    ListObjectsV2Output.add_member(:start_after, Shapes::ShapeRef.new(shape: StartAfter, location_name: "StartAfter"))
    ListObjectsV2Output.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    ListObjectsV2Output.struct_class = Types::ListObjectsV2Output

    ListObjectsV2Request.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListObjectsV2Request.add_member(:delimiter, Shapes::ShapeRef.new(shape: Delimiter, location: "querystring", location_name: "delimiter"))
    ListObjectsV2Request.add_member(:encoding_type, Shapes::ShapeRef.new(shape: EncodingType, location: "querystring", location_name: "encoding-type"))
    ListObjectsV2Request.add_member(:max_keys, Shapes::ShapeRef.new(shape: MaxKeys, location: "querystring", location_name: "max-keys"))
    ListObjectsV2Request.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location: "querystring", location_name: "prefix"))
    ListObjectsV2Request.add_member(:continuation_token, Shapes::ShapeRef.new(shape: Token, location: "querystring", location_name: "continuation-token"))
    ListObjectsV2Request.add_member(:fetch_owner, Shapes::ShapeRef.new(shape: FetchOwner, location: "querystring", location_name: "fetch-owner"))
    ListObjectsV2Request.add_member(:start_after, Shapes::ShapeRef.new(shape: StartAfter, location: "querystring", location_name: "start-after"))
    ListObjectsV2Request.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    ListObjectsV2Request.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListObjectsV2Request.struct_class = Types::ListObjectsV2Request

    ListPartsOutput.add_member(:abort_date, Shapes::ShapeRef.new(shape: AbortDate, location: "header", location_name: "x-amz-abort-date"))
    ListPartsOutput.add_member(:abort_rule_id, Shapes::ShapeRef.new(shape: AbortRuleId, location: "header", location_name: "x-amz-abort-rule-id"))
    ListPartsOutput.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, location_name: "Bucket"))
    ListPartsOutput.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    ListPartsOutput.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, location_name: "UploadId"))
    ListPartsOutput.add_member(:part_number_marker, Shapes::ShapeRef.new(shape: PartNumberMarker, location_name: "PartNumberMarker"))
    ListPartsOutput.add_member(:next_part_number_marker, Shapes::ShapeRef.new(shape: NextPartNumberMarker, location_name: "NextPartNumberMarker"))
    ListPartsOutput.add_member(:max_parts, Shapes::ShapeRef.new(shape: MaxParts, location_name: "MaxParts"))
    ListPartsOutput.add_member(:is_truncated, Shapes::ShapeRef.new(shape: IsTruncated, location_name: "IsTruncated"))
    ListPartsOutput.add_member(:parts, Shapes::ShapeRef.new(shape: Parts, location_name: "Part"))
    ListPartsOutput.add_member(:initiator, Shapes::ShapeRef.new(shape: Initiator, location_name: "Initiator"))
    ListPartsOutput.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    ListPartsOutput.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location_name: "StorageClass"))
    ListPartsOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    ListPartsOutput.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location_name: "ChecksumAlgorithm"))
    ListPartsOutput.struct_class = Types::ListPartsOutput

    ListPartsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    ListPartsRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    ListPartsRequest.add_member(:max_parts, Shapes::ShapeRef.new(shape: MaxParts, location: "querystring", location_name: "max-parts"))
    ListPartsRequest.add_member(:part_number_marker, Shapes::ShapeRef.new(shape: PartNumberMarker, location: "querystring", location_name: "part-number-marker"))
    ListPartsRequest.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, required: true, location: "querystring", location_name: "uploadId"))
    ListPartsRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    ListPartsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    ListPartsRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    ListPartsRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    ListPartsRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    ListPartsRequest.struct_class = Types::ListPartsRequest

    LoggingEnabled.add_member(:target_bucket, Shapes::ShapeRef.new(shape: TargetBucket, required: true, location_name: "TargetBucket"))
    LoggingEnabled.add_member(:target_grants, Shapes::ShapeRef.new(shape: TargetGrants, location_name: "TargetGrants"))
    LoggingEnabled.add_member(:target_prefix, Shapes::ShapeRef.new(shape: TargetPrefix, required: true, location_name: "TargetPrefix"))
    LoggingEnabled.struct_class = Types::LoggingEnabled

    Metadata.key = Shapes::ShapeRef.new(shape: MetadataKey)
    Metadata.value = Shapes::ShapeRef.new(shape: MetadataValue)

    MetadataEntry.add_member(:name, Shapes::ShapeRef.new(shape: MetadataKey, location_name: "Name"))
    MetadataEntry.add_member(:value, Shapes::ShapeRef.new(shape: MetadataValue, location_name: "Value"))
    MetadataEntry.struct_class = Types::MetadataEntry

    Metrics.add_member(:status, Shapes::ShapeRef.new(shape: MetricsStatus, required: true, location_name: "Status"))
    Metrics.add_member(:event_threshold, Shapes::ShapeRef.new(shape: ReplicationTimeValue, location_name: "EventThreshold"))
    Metrics.struct_class = Types::Metrics

    MetricsAndOperator.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    MetricsAndOperator.add_member(:tags, Shapes::ShapeRef.new(shape: TagSet, location_name: "Tag", metadata: {"flattened"=>true}))
    MetricsAndOperator.add_member(:access_point_arn, Shapes::ShapeRef.new(shape: AccessPointArn, location_name: "AccessPointArn"))
    MetricsAndOperator.struct_class = Types::MetricsAndOperator

    MetricsConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: MetricsId, required: true, location_name: "Id"))
    MetricsConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: MetricsFilter, location_name: "Filter"))
    MetricsConfiguration.struct_class = Types::MetricsConfiguration

    MetricsConfigurationList.member = Shapes::ShapeRef.new(shape: MetricsConfiguration)

    MetricsFilter.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    MetricsFilter.add_member(:tag, Shapes::ShapeRef.new(shape: Tag, location_name: "Tag"))
    MetricsFilter.add_member(:access_point_arn, Shapes::ShapeRef.new(shape: AccessPointArn, location_name: "AccessPointArn"))
    MetricsFilter.add_member(:and, Shapes::ShapeRef.new(shape: MetricsAndOperator, location_name: "And"))
    MetricsFilter.struct_class = Types::MetricsFilter

    MultipartUpload.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, location_name: "UploadId"))
    MultipartUpload.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    MultipartUpload.add_member(:initiated, Shapes::ShapeRef.new(shape: Initiated, location_name: "Initiated"))
    MultipartUpload.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location_name: "StorageClass"))
    MultipartUpload.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    MultipartUpload.add_member(:initiator, Shapes::ShapeRef.new(shape: Initiator, location_name: "Initiator"))
    MultipartUpload.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location_name: "ChecksumAlgorithm"))
    MultipartUpload.struct_class = Types::MultipartUpload

    MultipartUploadList.member = Shapes::ShapeRef.new(shape: MultipartUpload)

    NoSuchBucket.struct_class = Types::NoSuchBucket

    NoSuchKey.struct_class = Types::NoSuchKey

    NoSuchUpload.struct_class = Types::NoSuchUpload

    NoncurrentVersionExpiration.add_member(:noncurrent_days, Shapes::ShapeRef.new(shape: Days, location_name: "NoncurrentDays"))
    NoncurrentVersionExpiration.add_member(:newer_noncurrent_versions, Shapes::ShapeRef.new(shape: VersionCount, location_name: "NewerNoncurrentVersions"))
    NoncurrentVersionExpiration.struct_class = Types::NoncurrentVersionExpiration

    NoncurrentVersionTransition.add_member(:noncurrent_days, Shapes::ShapeRef.new(shape: Days, location_name: "NoncurrentDays"))
    NoncurrentVersionTransition.add_member(:storage_class, Shapes::ShapeRef.new(shape: TransitionStorageClass, location_name: "StorageClass"))
    NoncurrentVersionTransition.add_member(:newer_noncurrent_versions, Shapes::ShapeRef.new(shape: VersionCount, location_name: "NewerNoncurrentVersions"))
    NoncurrentVersionTransition.struct_class = Types::NoncurrentVersionTransition

    NoncurrentVersionTransitionList.member = Shapes::ShapeRef.new(shape: NoncurrentVersionTransition)

    NotificationConfiguration.add_member(:topic_configurations, Shapes::ShapeRef.new(shape: TopicConfigurationList, location_name: "TopicConfiguration"))
    NotificationConfiguration.add_member(:queue_configurations, Shapes::ShapeRef.new(shape: QueueConfigurationList, location_name: "QueueConfiguration"))
    NotificationConfiguration.add_member(:lambda_function_configurations, Shapes::ShapeRef.new(shape: LambdaFunctionConfigurationList, location_name: "CloudFunctionConfiguration"))
    NotificationConfiguration.add_member(:event_bridge_configuration, Shapes::ShapeRef.new(shape: EventBridgeConfiguration, location_name: "EventBridgeConfiguration"))
    NotificationConfiguration.struct_class = Types::NotificationConfiguration

    NotificationConfigurationDeprecated.add_member(:topic_configuration, Shapes::ShapeRef.new(shape: TopicConfigurationDeprecated, location_name: "TopicConfiguration"))
    NotificationConfigurationDeprecated.add_member(:queue_configuration, Shapes::ShapeRef.new(shape: QueueConfigurationDeprecated, location_name: "QueueConfiguration"))
    NotificationConfigurationDeprecated.add_member(:cloud_function_configuration, Shapes::ShapeRef.new(shape: CloudFunctionConfiguration, location_name: "CloudFunctionConfiguration"))
    NotificationConfigurationDeprecated.struct_class = Types::NotificationConfigurationDeprecated

    NotificationConfigurationFilter.add_member(:key, Shapes::ShapeRef.new(shape: S3KeyFilter, location_name: "S3Key"))
    NotificationConfigurationFilter.struct_class = Types::NotificationConfigurationFilter

    Object.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    Object.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location_name: "LastModified"))
    Object.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    Object.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithmList, location_name: "ChecksumAlgorithm"))
    Object.add_member(:size, Shapes::ShapeRef.new(shape: Size, location_name: "Size"))
    Object.add_member(:storage_class, Shapes::ShapeRef.new(shape: ObjectStorageClass, location_name: "StorageClass"))
    Object.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    Object.struct_class = Types::Object

    ObjectAlreadyInActiveTierError.struct_class = Types::ObjectAlreadyInActiveTierError

    ObjectAttributesList.member = Shapes::ShapeRef.new(shape: ObjectAttributes)

    ObjectIdentifier.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location_name: "Key"))
    ObjectIdentifier.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location_name: "VersionId"))
    ObjectIdentifier.struct_class = Types::ObjectIdentifier

    ObjectIdentifierList.member = Shapes::ShapeRef.new(shape: ObjectIdentifier)

    ObjectList.member = Shapes::ShapeRef.new(shape: Object)

    ObjectLockConfiguration.add_member(:object_lock_enabled, Shapes::ShapeRef.new(shape: ObjectLockEnabled, location_name: "ObjectLockEnabled"))
    ObjectLockConfiguration.add_member(:rule, Shapes::ShapeRef.new(shape: ObjectLockRule, location_name: "Rule"))
    ObjectLockConfiguration.struct_class = Types::ObjectLockConfiguration

    ObjectLockLegalHold.add_member(:status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location_name: "Status"))
    ObjectLockLegalHold.struct_class = Types::ObjectLockLegalHold

    ObjectLockRetention.add_member(:mode, Shapes::ShapeRef.new(shape: ObjectLockRetentionMode, location_name: "Mode"))
    ObjectLockRetention.add_member(:retain_until_date, Shapes::ShapeRef.new(shape: Date, location_name: "RetainUntilDate"))
    ObjectLockRetention.struct_class = Types::ObjectLockRetention

    ObjectLockRule.add_member(:default_retention, Shapes::ShapeRef.new(shape: DefaultRetention, location_name: "DefaultRetention"))
    ObjectLockRule.struct_class = Types::ObjectLockRule

    ObjectNotInActiveTierError.struct_class = Types::ObjectNotInActiveTierError

    ObjectPart.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, location_name: "PartNumber"))
    ObjectPart.add_member(:size, Shapes::ShapeRef.new(shape: Size, location_name: "Size"))
    ObjectPart.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    ObjectPart.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    ObjectPart.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    ObjectPart.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    ObjectPart.struct_class = Types::ObjectPart

    ObjectVersion.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    ObjectVersion.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithmList, location_name: "ChecksumAlgorithm"))
    ObjectVersion.add_member(:size, Shapes::ShapeRef.new(shape: Size, location_name: "Size"))
    ObjectVersion.add_member(:storage_class, Shapes::ShapeRef.new(shape: ObjectVersionStorageClass, location_name: "StorageClass"))
    ObjectVersion.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, location_name: "Key"))
    ObjectVersion.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location_name: "VersionId"))
    ObjectVersion.add_member(:is_latest, Shapes::ShapeRef.new(shape: IsLatest, location_name: "IsLatest"))
    ObjectVersion.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location_name: "LastModified"))
    ObjectVersion.add_member(:owner, Shapes::ShapeRef.new(shape: Owner, location_name: "Owner"))
    ObjectVersion.struct_class = Types::ObjectVersion

    ObjectVersionList.member = Shapes::ShapeRef.new(shape: ObjectVersion)

    OutputLocation.add_member(:s3, Shapes::ShapeRef.new(shape: S3Location, location_name: "S3"))
    OutputLocation.struct_class = Types::OutputLocation

    OutputSerialization.add_member(:csv, Shapes::ShapeRef.new(shape: CSVOutput, location_name: "CSV"))
    OutputSerialization.add_member(:json, Shapes::ShapeRef.new(shape: JSONOutput, location_name: "JSON"))
    OutputSerialization.struct_class = Types::OutputSerialization

    Owner.add_member(:display_name, Shapes::ShapeRef.new(shape: DisplayName, location_name: "DisplayName"))
    Owner.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    Owner.struct_class = Types::Owner

    OwnershipControls.add_member(:rules, Shapes::ShapeRef.new(shape: OwnershipControlsRules, required: true, location_name: "Rule"))
    OwnershipControls.struct_class = Types::OwnershipControls

    OwnershipControlsRule.add_member(:object_ownership, Shapes::ShapeRef.new(shape: ObjectOwnership, required: true, location_name: "ObjectOwnership"))
    OwnershipControlsRule.struct_class = Types::OwnershipControlsRule

    OwnershipControlsRules.member = Shapes::ShapeRef.new(shape: OwnershipControlsRule)

    ParquetInput.struct_class = Types::ParquetInput

    Part.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, location_name: "PartNumber"))
    Part.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location_name: "LastModified"))
    Part.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location_name: "ETag"))
    Part.add_member(:size, Shapes::ShapeRef.new(shape: Size, location_name: "Size"))
    Part.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location_name: "ChecksumCRC32"))
    Part.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location_name: "ChecksumCRC32C"))
    Part.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location_name: "ChecksumSHA1"))
    Part.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location_name: "ChecksumSHA256"))
    Part.struct_class = Types::Part

    Parts.member = Shapes::ShapeRef.new(shape: Part)

    PartsList.member = Shapes::ShapeRef.new(shape: ObjectPart)

    PolicyStatus.add_member(:is_public, Shapes::ShapeRef.new(shape: IsPublic, location_name: "IsPublic"))
    PolicyStatus.struct_class = Types::PolicyStatus

    Progress.add_member(:bytes_scanned, Shapes::ShapeRef.new(shape: BytesScanned, location_name: "BytesScanned"))
    Progress.add_member(:bytes_processed, Shapes::ShapeRef.new(shape: BytesProcessed, location_name: "BytesProcessed"))
    Progress.add_member(:bytes_returned, Shapes::ShapeRef.new(shape: BytesReturned, location_name: "BytesReturned"))
    Progress.struct_class = Types::Progress

    ProgressEvent.add_member(:details, Shapes::ShapeRef.new(shape: Progress, eventpayload: true, eventpayload_type: 'structure', location_name: "Details", metadata: {"eventpayload"=>true}))
    ProgressEvent.struct_class = Types::ProgressEvent

    PublicAccessBlockConfiguration.add_member(:block_public_acls, Shapes::ShapeRef.new(shape: Setting, location_name: "BlockPublicAcls"))
    PublicAccessBlockConfiguration.add_member(:ignore_public_acls, Shapes::ShapeRef.new(shape: Setting, location_name: "IgnorePublicAcls"))
    PublicAccessBlockConfiguration.add_member(:block_public_policy, Shapes::ShapeRef.new(shape: Setting, location_name: "BlockPublicPolicy"))
    PublicAccessBlockConfiguration.add_member(:restrict_public_buckets, Shapes::ShapeRef.new(shape: Setting, location_name: "RestrictPublicBuckets"))
    PublicAccessBlockConfiguration.struct_class = Types::PublicAccessBlockConfiguration

    PutBucketAccelerateConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketAccelerateConfigurationRequest.add_member(:accelerate_configuration, Shapes::ShapeRef.new(shape: AccelerateConfiguration, required: true, location_name: "AccelerateConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketAccelerateConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketAccelerateConfigurationRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketAccelerateConfigurationRequest.struct_class = Types::PutBucketAccelerateConfigurationRequest
    PutBucketAccelerateConfigurationRequest[:payload] = :accelerate_configuration
    PutBucketAccelerateConfigurationRequest[:payload_member] = PutBucketAccelerateConfigurationRequest.member(:accelerate_configuration)

    PutBucketAclRequest.add_member(:acl, Shapes::ShapeRef.new(shape: BucketCannedACL, location: "header", location_name: "x-amz-acl"))
    PutBucketAclRequest.add_member(:access_control_policy, Shapes::ShapeRef.new(shape: AccessControlPolicy, location_name: "AccessControlPolicy", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketAclRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketAclRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketAclRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketAclRequest.add_member(:grant_full_control, Shapes::ShapeRef.new(shape: GrantFullControl, location: "header", location_name: "x-amz-grant-full-control"))
    PutBucketAclRequest.add_member(:grant_read, Shapes::ShapeRef.new(shape: GrantRead, location: "header", location_name: "x-amz-grant-read"))
    PutBucketAclRequest.add_member(:grant_read_acp, Shapes::ShapeRef.new(shape: GrantReadACP, location: "header", location_name: "x-amz-grant-read-acp"))
    PutBucketAclRequest.add_member(:grant_write, Shapes::ShapeRef.new(shape: GrantWrite, location: "header", location_name: "x-amz-grant-write"))
    PutBucketAclRequest.add_member(:grant_write_acp, Shapes::ShapeRef.new(shape: GrantWriteACP, location: "header", location_name: "x-amz-grant-write-acp"))
    PutBucketAclRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketAclRequest.struct_class = Types::PutBucketAclRequest
    PutBucketAclRequest[:payload] = :access_control_policy
    PutBucketAclRequest[:payload_member] = PutBucketAclRequest.member(:access_control_policy)

    PutBucketAnalyticsConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketAnalyticsConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: AnalyticsId, required: true, location: "querystring", location_name: "id"))
    PutBucketAnalyticsConfigurationRequest.add_member(:analytics_configuration, Shapes::ShapeRef.new(shape: AnalyticsConfiguration, required: true, location_name: "AnalyticsConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketAnalyticsConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketAnalyticsConfigurationRequest.struct_class = Types::PutBucketAnalyticsConfigurationRequest
    PutBucketAnalyticsConfigurationRequest[:payload] = :analytics_configuration
    PutBucketAnalyticsConfigurationRequest[:payload_member] = PutBucketAnalyticsConfigurationRequest.member(:analytics_configuration)

    PutBucketCorsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketCorsRequest.add_member(:cors_configuration, Shapes::ShapeRef.new(shape: CORSConfiguration, required: true, location_name: "CORSConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketCorsRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketCorsRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketCorsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketCorsRequest.struct_class = Types::PutBucketCorsRequest
    PutBucketCorsRequest[:payload] = :cors_configuration
    PutBucketCorsRequest[:payload_member] = PutBucketCorsRequest.member(:cors_configuration)

    PutBucketEncryptionRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketEncryptionRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketEncryptionRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketEncryptionRequest.add_member(:server_side_encryption_configuration, Shapes::ShapeRef.new(shape: ServerSideEncryptionConfiguration, required: true, location_name: "ServerSideEncryptionConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketEncryptionRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketEncryptionRequest.struct_class = Types::PutBucketEncryptionRequest
    PutBucketEncryptionRequest[:payload] = :server_side_encryption_configuration
    PutBucketEncryptionRequest[:payload_member] = PutBucketEncryptionRequest.member(:server_side_encryption_configuration)

    PutBucketIntelligentTieringConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketIntelligentTieringConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: IntelligentTieringId, required: true, location: "querystring", location_name: "id"))
    PutBucketIntelligentTieringConfigurationRequest.add_member(:intelligent_tiering_configuration, Shapes::ShapeRef.new(shape: IntelligentTieringConfiguration, required: true, location_name: "IntelligentTieringConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketIntelligentTieringConfigurationRequest.struct_class = Types::PutBucketIntelligentTieringConfigurationRequest
    PutBucketIntelligentTieringConfigurationRequest[:payload] = :intelligent_tiering_configuration
    PutBucketIntelligentTieringConfigurationRequest[:payload_member] = PutBucketIntelligentTieringConfigurationRequest.member(:intelligent_tiering_configuration)

    PutBucketInventoryConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketInventoryConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: InventoryId, required: true, location: "querystring", location_name: "id"))
    PutBucketInventoryConfigurationRequest.add_member(:inventory_configuration, Shapes::ShapeRef.new(shape: InventoryConfiguration, required: true, location_name: "InventoryConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketInventoryConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketInventoryConfigurationRequest.struct_class = Types::PutBucketInventoryConfigurationRequest
    PutBucketInventoryConfigurationRequest[:payload] = :inventory_configuration
    PutBucketInventoryConfigurationRequest[:payload_member] = PutBucketInventoryConfigurationRequest.member(:inventory_configuration)

    PutBucketLifecycleConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketLifecycleConfigurationRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketLifecycleConfigurationRequest.add_member(:lifecycle_configuration, Shapes::ShapeRef.new(shape: BucketLifecycleConfiguration, location_name: "LifecycleConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketLifecycleConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketLifecycleConfigurationRequest.struct_class = Types::PutBucketLifecycleConfigurationRequest
    PutBucketLifecycleConfigurationRequest[:payload] = :lifecycle_configuration
    PutBucketLifecycleConfigurationRequest[:payload_member] = PutBucketLifecycleConfigurationRequest.member(:lifecycle_configuration)

    PutBucketLifecycleRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketLifecycleRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketLifecycleRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketLifecycleRequest.add_member(:lifecycle_configuration, Shapes::ShapeRef.new(shape: LifecycleConfiguration, location_name: "LifecycleConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketLifecycleRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketLifecycleRequest.struct_class = Types::PutBucketLifecycleRequest
    PutBucketLifecycleRequest[:payload] = :lifecycle_configuration
    PutBucketLifecycleRequest[:payload_member] = PutBucketLifecycleRequest.member(:lifecycle_configuration)

    PutBucketLoggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketLoggingRequest.add_member(:bucket_logging_status, Shapes::ShapeRef.new(shape: BucketLoggingStatus, required: true, location_name: "BucketLoggingStatus", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketLoggingRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketLoggingRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketLoggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketLoggingRequest.struct_class = Types::PutBucketLoggingRequest
    PutBucketLoggingRequest[:payload] = :bucket_logging_status
    PutBucketLoggingRequest[:payload_member] = PutBucketLoggingRequest.member(:bucket_logging_status)

    PutBucketMetricsConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketMetricsConfigurationRequest.add_member(:id, Shapes::ShapeRef.new(shape: MetricsId, required: true, location: "querystring", location_name: "id"))
    PutBucketMetricsConfigurationRequest.add_member(:metrics_configuration, Shapes::ShapeRef.new(shape: MetricsConfiguration, required: true, location_name: "MetricsConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketMetricsConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketMetricsConfigurationRequest.struct_class = Types::PutBucketMetricsConfigurationRequest
    PutBucketMetricsConfigurationRequest[:payload] = :metrics_configuration
    PutBucketMetricsConfigurationRequest[:payload_member] = PutBucketMetricsConfigurationRequest.member(:metrics_configuration)

    PutBucketNotificationConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketNotificationConfigurationRequest.add_member(:notification_configuration, Shapes::ShapeRef.new(shape: NotificationConfiguration, required: true, location_name: "NotificationConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketNotificationConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketNotificationConfigurationRequest.add_member(:skip_destination_validation, Shapes::ShapeRef.new(shape: SkipValidation, location: "header", location_name: "x-amz-skip-destination-validation"))
    PutBucketNotificationConfigurationRequest.struct_class = Types::PutBucketNotificationConfigurationRequest
    PutBucketNotificationConfigurationRequest[:payload] = :notification_configuration
    PutBucketNotificationConfigurationRequest[:payload_member] = PutBucketNotificationConfigurationRequest.member(:notification_configuration)

    PutBucketNotificationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketNotificationRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketNotificationRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketNotificationRequest.add_member(:notification_configuration, Shapes::ShapeRef.new(shape: NotificationConfigurationDeprecated, required: true, location_name: "NotificationConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketNotificationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketNotificationRequest.struct_class = Types::PutBucketNotificationRequest
    PutBucketNotificationRequest[:payload] = :notification_configuration
    PutBucketNotificationRequest[:payload_member] = PutBucketNotificationRequest.member(:notification_configuration)

    PutBucketOwnershipControlsRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketOwnershipControlsRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketOwnershipControlsRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketOwnershipControlsRequest.add_member(:ownership_controls, Shapes::ShapeRef.new(shape: OwnershipControls, required: true, location_name: "OwnershipControls", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketOwnershipControlsRequest.struct_class = Types::PutBucketOwnershipControlsRequest
    PutBucketOwnershipControlsRequest[:payload] = :ownership_controls
    PutBucketOwnershipControlsRequest[:payload_member] = PutBucketOwnershipControlsRequest.member(:ownership_controls)

    PutBucketPolicyRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketPolicyRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketPolicyRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketPolicyRequest.add_member(:confirm_remove_self_bucket_access, Shapes::ShapeRef.new(shape: ConfirmRemoveSelfBucketAccess, location: "header", location_name: "x-amz-confirm-remove-self-bucket-access"))
    PutBucketPolicyRequest.add_member(:policy, Shapes::ShapeRef.new(shape: Policy, required: true, location_name: "Policy"))
    PutBucketPolicyRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketPolicyRequest.struct_class = Types::PutBucketPolicyRequest
    PutBucketPolicyRequest[:payload] = :policy
    PutBucketPolicyRequest[:payload_member] = PutBucketPolicyRequest.member(:policy)

    PutBucketReplicationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketReplicationRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketReplicationRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketReplicationRequest.add_member(:replication_configuration, Shapes::ShapeRef.new(shape: ReplicationConfiguration, required: true, location_name: "ReplicationConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketReplicationRequest.add_member(:token, Shapes::ShapeRef.new(shape: ObjectLockToken, location: "header", location_name: "x-amz-bucket-object-lock-token"))
    PutBucketReplicationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketReplicationRequest.struct_class = Types::PutBucketReplicationRequest
    PutBucketReplicationRequest[:payload] = :replication_configuration
    PutBucketReplicationRequest[:payload_member] = PutBucketReplicationRequest.member(:replication_configuration)

    PutBucketRequestPaymentRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketRequestPaymentRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketRequestPaymentRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketRequestPaymentRequest.add_member(:request_payment_configuration, Shapes::ShapeRef.new(shape: RequestPaymentConfiguration, required: true, location_name: "RequestPaymentConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketRequestPaymentRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketRequestPaymentRequest.struct_class = Types::PutBucketRequestPaymentRequest
    PutBucketRequestPaymentRequest[:payload] = :request_payment_configuration
    PutBucketRequestPaymentRequest[:payload_member] = PutBucketRequestPaymentRequest.member(:request_payment_configuration)

    PutBucketTaggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketTaggingRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketTaggingRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketTaggingRequest.add_member(:tagging, Shapes::ShapeRef.new(shape: Tagging, required: true, location_name: "Tagging", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketTaggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketTaggingRequest.struct_class = Types::PutBucketTaggingRequest
    PutBucketTaggingRequest[:payload] = :tagging
    PutBucketTaggingRequest[:payload_member] = PutBucketTaggingRequest.member(:tagging)

    PutBucketVersioningRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketVersioningRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketVersioningRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketVersioningRequest.add_member(:mfa, Shapes::ShapeRef.new(shape: MFA, location: "header", location_name: "x-amz-mfa"))
    PutBucketVersioningRequest.add_member(:versioning_configuration, Shapes::ShapeRef.new(shape: VersioningConfiguration, required: true, location_name: "VersioningConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketVersioningRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketVersioningRequest.struct_class = Types::PutBucketVersioningRequest
    PutBucketVersioningRequest[:payload] = :versioning_configuration
    PutBucketVersioningRequest[:payload_member] = PutBucketVersioningRequest.member(:versioning_configuration)

    PutBucketWebsiteRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutBucketWebsiteRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutBucketWebsiteRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutBucketWebsiteRequest.add_member(:website_configuration, Shapes::ShapeRef.new(shape: WebsiteConfiguration, required: true, location_name: "WebsiteConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutBucketWebsiteRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutBucketWebsiteRequest.struct_class = Types::PutBucketWebsiteRequest
    PutBucketWebsiteRequest[:payload] = :website_configuration
    PutBucketWebsiteRequest[:payload_member] = PutBucketWebsiteRequest.member(:website_configuration)

    PutObjectAclOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    PutObjectAclOutput.struct_class = Types::PutObjectAclOutput

    PutObjectAclRequest.add_member(:acl, Shapes::ShapeRef.new(shape: ObjectCannedACL, location: "header", location_name: "x-amz-acl"))
    PutObjectAclRequest.add_member(:access_control_policy, Shapes::ShapeRef.new(shape: AccessControlPolicy, location_name: "AccessControlPolicy", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutObjectAclRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutObjectAclRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutObjectAclRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutObjectAclRequest.add_member(:grant_full_control, Shapes::ShapeRef.new(shape: GrantFullControl, location: "header", location_name: "x-amz-grant-full-control"))
    PutObjectAclRequest.add_member(:grant_read, Shapes::ShapeRef.new(shape: GrantRead, location: "header", location_name: "x-amz-grant-read"))
    PutObjectAclRequest.add_member(:grant_read_acp, Shapes::ShapeRef.new(shape: GrantReadACP, location: "header", location_name: "x-amz-grant-read-acp"))
    PutObjectAclRequest.add_member(:grant_write, Shapes::ShapeRef.new(shape: GrantWrite, location: "header", location_name: "x-amz-grant-write"))
    PutObjectAclRequest.add_member(:grant_write_acp, Shapes::ShapeRef.new(shape: GrantWriteACP, location: "header", location_name: "x-amz-grant-write-acp"))
    PutObjectAclRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    PutObjectAclRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    PutObjectAclRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    PutObjectAclRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutObjectAclRequest.struct_class = Types::PutObjectAclRequest
    PutObjectAclRequest[:payload] = :access_control_policy
    PutObjectAclRequest[:payload_member] = PutObjectAclRequest.member(:access_control_policy)

    PutObjectLegalHoldOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    PutObjectLegalHoldOutput.struct_class = Types::PutObjectLegalHoldOutput

    PutObjectLegalHoldRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutObjectLegalHoldRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    PutObjectLegalHoldRequest.add_member(:legal_hold, Shapes::ShapeRef.new(shape: ObjectLockLegalHold, location_name: "LegalHold", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutObjectLegalHoldRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    PutObjectLegalHoldRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    PutObjectLegalHoldRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutObjectLegalHoldRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutObjectLegalHoldRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutObjectLegalHoldRequest.struct_class = Types::PutObjectLegalHoldRequest
    PutObjectLegalHoldRequest[:payload] = :legal_hold
    PutObjectLegalHoldRequest[:payload_member] = PutObjectLegalHoldRequest.member(:legal_hold)

    PutObjectLockConfigurationOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    PutObjectLockConfigurationOutput.struct_class = Types::PutObjectLockConfigurationOutput

    PutObjectLockConfigurationRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutObjectLockConfigurationRequest.add_member(:object_lock_configuration, Shapes::ShapeRef.new(shape: ObjectLockConfiguration, location_name: "ObjectLockConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutObjectLockConfigurationRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    PutObjectLockConfigurationRequest.add_member(:token, Shapes::ShapeRef.new(shape: ObjectLockToken, location: "header", location_name: "x-amz-bucket-object-lock-token"))
    PutObjectLockConfigurationRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutObjectLockConfigurationRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutObjectLockConfigurationRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutObjectLockConfigurationRequest.struct_class = Types::PutObjectLockConfigurationRequest
    PutObjectLockConfigurationRequest[:payload] = :object_lock_configuration
    PutObjectLockConfigurationRequest[:payload_member] = PutObjectLockConfigurationRequest.member(:object_lock_configuration)

    PutObjectOutput.add_member(:expiration, Shapes::ShapeRef.new(shape: Expiration, location: "header", location_name: "x-amz-expiration"))
    PutObjectOutput.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location: "header", location_name: "ETag"))
    PutObjectOutput.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    PutObjectOutput.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    PutObjectOutput.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    PutObjectOutput.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    PutObjectOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    PutObjectOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    PutObjectOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    PutObjectOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    PutObjectOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    PutObjectOutput.add_member(:ssekms_encryption_context, Shapes::ShapeRef.new(shape: SSEKMSEncryptionContext, location: "header", location_name: "x-amz-server-side-encryption-context"))
    PutObjectOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    PutObjectOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    PutObjectOutput.struct_class = Types::PutObjectOutput

    PutObjectRequest.add_member(:acl, Shapes::ShapeRef.new(shape: ObjectCannedACL, location: "header", location_name: "x-amz-acl"))
    PutObjectRequest.add_member(:body, Shapes::ShapeRef.new(shape: Body, location_name: "Body", metadata: {"streaming"=>true}))
    PutObjectRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutObjectRequest.add_member(:cache_control, Shapes::ShapeRef.new(shape: CacheControl, location: "header", location_name: "Cache-Control"))
    PutObjectRequest.add_member(:content_disposition, Shapes::ShapeRef.new(shape: ContentDisposition, location: "header", location_name: "Content-Disposition"))
    PutObjectRequest.add_member(:content_encoding, Shapes::ShapeRef.new(shape: ContentEncoding, location: "header", location_name: "Content-Encoding"))
    PutObjectRequest.add_member(:content_language, Shapes::ShapeRef.new(shape: ContentLanguage, location: "header", location_name: "Content-Language"))
    PutObjectRequest.add_member(:content_length, Shapes::ShapeRef.new(shape: ContentLength, location: "header", location_name: "Content-Length"))
    PutObjectRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutObjectRequest.add_member(:content_type, Shapes::ShapeRef.new(shape: ContentType, location: "header", location_name: "Content-Type"))
    PutObjectRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutObjectRequest.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    PutObjectRequest.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    PutObjectRequest.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    PutObjectRequest.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    PutObjectRequest.add_member(:expires, Shapes::ShapeRef.new(shape: Expires, location: "header", location_name: "Expires"))
    PutObjectRequest.add_member(:grant_full_control, Shapes::ShapeRef.new(shape: GrantFullControl, location: "header", location_name: "x-amz-grant-full-control"))
    PutObjectRequest.add_member(:grant_read, Shapes::ShapeRef.new(shape: GrantRead, location: "header", location_name: "x-amz-grant-read"))
    PutObjectRequest.add_member(:grant_read_acp, Shapes::ShapeRef.new(shape: GrantReadACP, location: "header", location_name: "x-amz-grant-read-acp"))
    PutObjectRequest.add_member(:grant_write_acp, Shapes::ShapeRef.new(shape: GrantWriteACP, location: "header", location_name: "x-amz-grant-write-acp"))
    PutObjectRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    PutObjectRequest.add_member(:metadata, Shapes::ShapeRef.new(shape: Metadata, location: "headers", location_name: "x-amz-meta-"))
    PutObjectRequest.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    PutObjectRequest.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location: "header", location_name: "x-amz-storage-class"))
    PutObjectRequest.add_member(:website_redirect_location, Shapes::ShapeRef.new(shape: WebsiteRedirectLocation, location: "header", location_name: "x-amz-website-redirect-location"))
    PutObjectRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    PutObjectRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    PutObjectRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    PutObjectRequest.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    PutObjectRequest.add_member(:ssekms_encryption_context, Shapes::ShapeRef.new(shape: SSEKMSEncryptionContext, location: "header", location_name: "x-amz-server-side-encryption-context"))
    PutObjectRequest.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    PutObjectRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    PutObjectRequest.add_member(:tagging, Shapes::ShapeRef.new(shape: TaggingHeader, location: "header", location_name: "x-amz-tagging"))
    PutObjectRequest.add_member(:object_lock_mode, Shapes::ShapeRef.new(shape: ObjectLockMode, location: "header", location_name: "x-amz-object-lock-mode"))
    PutObjectRequest.add_member(:object_lock_retain_until_date, Shapes::ShapeRef.new(shape: ObjectLockRetainUntilDate, location: "header", location_name: "x-amz-object-lock-retain-until-date"))
    PutObjectRequest.add_member(:object_lock_legal_hold_status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location: "header", location_name: "x-amz-object-lock-legal-hold"))
    PutObjectRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutObjectRequest.struct_class = Types::PutObjectRequest
    PutObjectRequest[:payload] = :body
    PutObjectRequest[:payload_member] = PutObjectRequest.member(:body)

    PutObjectRetentionOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    PutObjectRetentionOutput.struct_class = Types::PutObjectRetentionOutput

    PutObjectRetentionRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutObjectRetentionRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    PutObjectRetentionRequest.add_member(:retention, Shapes::ShapeRef.new(shape: ObjectLockRetention, location_name: "Retention", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutObjectRetentionRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    PutObjectRetentionRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    PutObjectRetentionRequest.add_member(:bypass_governance_retention, Shapes::ShapeRef.new(shape: BypassGovernanceRetention, location: "header", location_name: "x-amz-bypass-governance-retention"))
    PutObjectRetentionRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutObjectRetentionRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutObjectRetentionRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutObjectRetentionRequest.struct_class = Types::PutObjectRetentionRequest
    PutObjectRetentionRequest[:payload] = :retention
    PutObjectRetentionRequest[:payload_member] = PutObjectRetentionRequest.member(:retention)

    PutObjectTaggingOutput.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-version-id"))
    PutObjectTaggingOutput.struct_class = Types::PutObjectTaggingOutput

    PutObjectTaggingRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutObjectTaggingRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    PutObjectTaggingRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    PutObjectTaggingRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutObjectTaggingRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutObjectTaggingRequest.add_member(:tagging, Shapes::ShapeRef.new(shape: Tagging, required: true, location_name: "Tagging", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutObjectTaggingRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutObjectTaggingRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    PutObjectTaggingRequest.struct_class = Types::PutObjectTaggingRequest
    PutObjectTaggingRequest[:payload] = :tagging
    PutObjectTaggingRequest[:payload_member] = PutObjectTaggingRequest.member(:tagging)

    PutPublicAccessBlockRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    PutPublicAccessBlockRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    PutPublicAccessBlockRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    PutPublicAccessBlockRequest.add_member(:public_access_block_configuration, Shapes::ShapeRef.new(shape: PublicAccessBlockConfiguration, required: true, location_name: "PublicAccessBlockConfiguration", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    PutPublicAccessBlockRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    PutPublicAccessBlockRequest.struct_class = Types::PutPublicAccessBlockRequest
    PutPublicAccessBlockRequest[:payload] = :public_access_block_configuration
    PutPublicAccessBlockRequest[:payload_member] = PutPublicAccessBlockRequest.member(:public_access_block_configuration)

    QueueConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: NotificationId, location_name: "Id"))
    QueueConfiguration.add_member(:queue_arn, Shapes::ShapeRef.new(shape: QueueArn, required: true, location_name: "Queue"))
    QueueConfiguration.add_member(:events, Shapes::ShapeRef.new(shape: EventList, required: true, location_name: "Event"))
    QueueConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: NotificationConfigurationFilter, location_name: "Filter"))
    QueueConfiguration.struct_class = Types::QueueConfiguration

    QueueConfigurationDeprecated.add_member(:id, Shapes::ShapeRef.new(shape: NotificationId, location_name: "Id"))
    QueueConfigurationDeprecated.add_member(:event, Shapes::ShapeRef.new(shape: Event, deprecated: true, location_name: "Event"))
    QueueConfigurationDeprecated.add_member(:events, Shapes::ShapeRef.new(shape: EventList, location_name: "Event"))
    QueueConfigurationDeprecated.add_member(:queue, Shapes::ShapeRef.new(shape: QueueArn, location_name: "Queue"))
    QueueConfigurationDeprecated.struct_class = Types::QueueConfigurationDeprecated

    QueueConfigurationList.member = Shapes::ShapeRef.new(shape: QueueConfiguration)

    RecordsEvent.add_member(:payload, Shapes::ShapeRef.new(shape: Body, eventpayload: true, eventpayload_type: 'blob', location_name: "Payload", metadata: {"eventpayload"=>true}))
    RecordsEvent.struct_class = Types::RecordsEvent

    Redirect.add_member(:host_name, Shapes::ShapeRef.new(shape: HostName, location_name: "HostName"))
    Redirect.add_member(:http_redirect_code, Shapes::ShapeRef.new(shape: HttpRedirectCode, location_name: "HttpRedirectCode"))
    Redirect.add_member(:protocol, Shapes::ShapeRef.new(shape: Protocol, location_name: "Protocol"))
    Redirect.add_member(:replace_key_prefix_with, Shapes::ShapeRef.new(shape: ReplaceKeyPrefixWith, location_name: "ReplaceKeyPrefixWith"))
    Redirect.add_member(:replace_key_with, Shapes::ShapeRef.new(shape: ReplaceKeyWith, location_name: "ReplaceKeyWith"))
    Redirect.struct_class = Types::Redirect

    RedirectAllRequestsTo.add_member(:host_name, Shapes::ShapeRef.new(shape: HostName, required: true, location_name: "HostName"))
    RedirectAllRequestsTo.add_member(:protocol, Shapes::ShapeRef.new(shape: Protocol, location_name: "Protocol"))
    RedirectAllRequestsTo.struct_class = Types::RedirectAllRequestsTo

    ReplicaModifications.add_member(:status, Shapes::ShapeRef.new(shape: ReplicaModificationsStatus, required: true, location_name: "Status"))
    ReplicaModifications.struct_class = Types::ReplicaModifications

    ReplicationConfiguration.add_member(:role, Shapes::ShapeRef.new(shape: Role, required: true, location_name: "Role"))
    ReplicationConfiguration.add_member(:rules, Shapes::ShapeRef.new(shape: ReplicationRules, required: true, location_name: "Rule"))
    ReplicationConfiguration.struct_class = Types::ReplicationConfiguration

    ReplicationRule.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    ReplicationRule.add_member(:priority, Shapes::ShapeRef.new(shape: Priority, location_name: "Priority"))
    ReplicationRule.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, deprecated: true, location_name: "Prefix"))
    ReplicationRule.add_member(:filter, Shapes::ShapeRef.new(shape: ReplicationRuleFilter, location_name: "Filter"))
    ReplicationRule.add_member(:status, Shapes::ShapeRef.new(shape: ReplicationRuleStatus, required: true, location_name: "Status"))
    ReplicationRule.add_member(:source_selection_criteria, Shapes::ShapeRef.new(shape: SourceSelectionCriteria, location_name: "SourceSelectionCriteria"))
    ReplicationRule.add_member(:existing_object_replication, Shapes::ShapeRef.new(shape: ExistingObjectReplication, location_name: "ExistingObjectReplication"))
    ReplicationRule.add_member(:destination, Shapes::ShapeRef.new(shape: Destination, required: true, location_name: "Destination"))
    ReplicationRule.add_member(:delete_marker_replication, Shapes::ShapeRef.new(shape: DeleteMarkerReplication, location_name: "DeleteMarkerReplication"))
    ReplicationRule.struct_class = Types::ReplicationRule

    ReplicationRuleAndOperator.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    ReplicationRuleAndOperator.add_member(:tags, Shapes::ShapeRef.new(shape: TagSet, location_name: "Tag", metadata: {"flattened"=>true}))
    ReplicationRuleAndOperator.struct_class = Types::ReplicationRuleAndOperator

    ReplicationRuleFilter.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, location_name: "Prefix"))
    ReplicationRuleFilter.add_member(:tag, Shapes::ShapeRef.new(shape: Tag, location_name: "Tag"))
    ReplicationRuleFilter.add_member(:and, Shapes::ShapeRef.new(shape: ReplicationRuleAndOperator, location_name: "And"))
    ReplicationRuleFilter.struct_class = Types::ReplicationRuleFilter

    ReplicationRules.member = Shapes::ShapeRef.new(shape: ReplicationRule)

    ReplicationTime.add_member(:status, Shapes::ShapeRef.new(shape: ReplicationTimeStatus, required: true, location_name: "Status"))
    ReplicationTime.add_member(:time, Shapes::ShapeRef.new(shape: ReplicationTimeValue, required: true, location_name: "Time"))
    ReplicationTime.struct_class = Types::ReplicationTime

    ReplicationTimeValue.add_member(:minutes, Shapes::ShapeRef.new(shape: Minutes, location_name: "Minutes"))
    ReplicationTimeValue.struct_class = Types::ReplicationTimeValue

    RequestPaymentConfiguration.add_member(:payer, Shapes::ShapeRef.new(shape: Payer, required: true, location_name: "Payer"))
    RequestPaymentConfiguration.struct_class = Types::RequestPaymentConfiguration

    RequestProgress.add_member(:enabled, Shapes::ShapeRef.new(shape: EnableRequestProgress, location_name: "Enabled"))
    RequestProgress.struct_class = Types::RequestProgress

    RestoreObjectOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    RestoreObjectOutput.add_member(:restore_output_path, Shapes::ShapeRef.new(shape: RestoreOutputPath, location: "header", location_name: "x-amz-restore-output-path"))
    RestoreObjectOutput.struct_class = Types::RestoreObjectOutput

    RestoreObjectRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    RestoreObjectRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    RestoreObjectRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "querystring", location_name: "versionId"))
    RestoreObjectRequest.add_member(:restore_request, Shapes::ShapeRef.new(shape: RestoreRequest, location_name: "RestoreRequest", metadata: {"xmlNamespace"=>{"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}}))
    RestoreObjectRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    RestoreObjectRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    RestoreObjectRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    RestoreObjectRequest.struct_class = Types::RestoreObjectRequest
    RestoreObjectRequest[:payload] = :restore_request
    RestoreObjectRequest[:payload_member] = RestoreObjectRequest.member(:restore_request)

    RestoreRequest.add_member(:days, Shapes::ShapeRef.new(shape: Days, location_name: "Days"))
    RestoreRequest.add_member(:glacier_job_parameters, Shapes::ShapeRef.new(shape: GlacierJobParameters, location_name: "GlacierJobParameters"))
    RestoreRequest.add_member(:type, Shapes::ShapeRef.new(shape: RestoreRequestType, location_name: "Type"))
    RestoreRequest.add_member(:tier, Shapes::ShapeRef.new(shape: Tier, location_name: "Tier"))
    RestoreRequest.add_member(:description, Shapes::ShapeRef.new(shape: Description, location_name: "Description"))
    RestoreRequest.add_member(:select_parameters, Shapes::ShapeRef.new(shape: SelectParameters, location_name: "SelectParameters"))
    RestoreRequest.add_member(:output_location, Shapes::ShapeRef.new(shape: OutputLocation, location_name: "OutputLocation"))
    RestoreRequest.struct_class = Types::RestoreRequest

    RoutingRule.add_member(:condition, Shapes::ShapeRef.new(shape: Condition, location_name: "Condition"))
    RoutingRule.add_member(:redirect, Shapes::ShapeRef.new(shape: Redirect, required: true, location_name: "Redirect"))
    RoutingRule.struct_class = Types::RoutingRule

    RoutingRules.member = Shapes::ShapeRef.new(shape: RoutingRule, location_name: "RoutingRule")

    Rule.add_member(:expiration, Shapes::ShapeRef.new(shape: LifecycleExpiration, location_name: "Expiration"))
    Rule.add_member(:id, Shapes::ShapeRef.new(shape: ID, location_name: "ID"))
    Rule.add_member(:prefix, Shapes::ShapeRef.new(shape: Prefix, required: true, location_name: "Prefix"))
    Rule.add_member(:status, Shapes::ShapeRef.new(shape: ExpirationStatus, required: true, location_name: "Status"))
    Rule.add_member(:transition, Shapes::ShapeRef.new(shape: Transition, location_name: "Transition"))
    Rule.add_member(:noncurrent_version_transition, Shapes::ShapeRef.new(shape: NoncurrentVersionTransition, location_name: "NoncurrentVersionTransition"))
    Rule.add_member(:noncurrent_version_expiration, Shapes::ShapeRef.new(shape: NoncurrentVersionExpiration, location_name: "NoncurrentVersionExpiration"))
    Rule.add_member(:abort_incomplete_multipart_upload, Shapes::ShapeRef.new(shape: AbortIncompleteMultipartUpload, location_name: "AbortIncompleteMultipartUpload"))
    Rule.struct_class = Types::Rule

    Rules.member = Shapes::ShapeRef.new(shape: Rule)

    S3KeyFilter.add_member(:filter_rules, Shapes::ShapeRef.new(shape: FilterRuleList, location_name: "FilterRule"))
    S3KeyFilter.struct_class = Types::S3KeyFilter

    S3Location.add_member(:bucket_name, Shapes::ShapeRef.new(shape: BucketName, required: true, location_name: "BucketName"))
    S3Location.add_member(:prefix, Shapes::ShapeRef.new(shape: LocationPrefix, required: true, location_name: "Prefix"))
    S3Location.add_member(:encryption, Shapes::ShapeRef.new(shape: Encryption, location_name: "Encryption"))
    S3Location.add_member(:canned_acl, Shapes::ShapeRef.new(shape: ObjectCannedACL, location_name: "CannedACL"))
    S3Location.add_member(:access_control_list, Shapes::ShapeRef.new(shape: Grants, location_name: "AccessControlList"))
    S3Location.add_member(:tagging, Shapes::ShapeRef.new(shape: Tagging, location_name: "Tagging"))
    S3Location.add_member(:user_metadata, Shapes::ShapeRef.new(shape: UserMetadata, location_name: "UserMetadata"))
    S3Location.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location_name: "StorageClass"))
    S3Location.struct_class = Types::S3Location

    SSEKMS.add_member(:key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, required: true, location_name: "KeyId"))
    SSEKMS.struct_class = Types::SSEKMS

    SSES3.struct_class = Types::SSES3

    ScanRange.add_member(:start, Shapes::ShapeRef.new(shape: Start, location_name: "Start"))
    ScanRange.add_member(:end, Shapes::ShapeRef.new(shape: End, location_name: "End"))
    ScanRange.struct_class = Types::ScanRange

    SelectObjectContentEventStream.add_member(:records, Shapes::ShapeRef.new(shape: RecordsEvent, event: true, location_name: "Records"))
    SelectObjectContentEventStream.add_member(:stats, Shapes::ShapeRef.new(shape: StatsEvent, event: true, location_name: "Stats"))
    SelectObjectContentEventStream.add_member(:progress, Shapes::ShapeRef.new(shape: ProgressEvent, event: true, location_name: "Progress"))
    SelectObjectContentEventStream.add_member(:cont, Shapes::ShapeRef.new(shape: ContinuationEvent, event: true, location_name: "Cont"))
    SelectObjectContentEventStream.add_member(:end, Shapes::ShapeRef.new(shape: EndEvent, event: true, location_name: "End"))
    SelectObjectContentEventStream.struct_class = Types::SelectObjectContentEventStream

    SelectObjectContentOutput.add_member(:payload, Shapes::ShapeRef.new(shape: SelectObjectContentEventStream, eventstream: true, location_name: "Payload"))
    SelectObjectContentOutput.struct_class = Types::SelectObjectContentOutput
    SelectObjectContentOutput[:payload] = :payload
    SelectObjectContentOutput[:payload_member] = SelectObjectContentOutput.member(:payload)

    SelectObjectContentRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    SelectObjectContentRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    SelectObjectContentRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    SelectObjectContentRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    SelectObjectContentRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    SelectObjectContentRequest.add_member(:expression, Shapes::ShapeRef.new(shape: Expression, required: true, location_name: "Expression"))
    SelectObjectContentRequest.add_member(:expression_type, Shapes::ShapeRef.new(shape: ExpressionType, required: true, location_name: "ExpressionType"))
    SelectObjectContentRequest.add_member(:request_progress, Shapes::ShapeRef.new(shape: RequestProgress, location_name: "RequestProgress"))
    SelectObjectContentRequest.add_member(:input_serialization, Shapes::ShapeRef.new(shape: InputSerialization, required: true, location_name: "InputSerialization"))
    SelectObjectContentRequest.add_member(:output_serialization, Shapes::ShapeRef.new(shape: OutputSerialization, required: true, location_name: "OutputSerialization"))
    SelectObjectContentRequest.add_member(:scan_range, Shapes::ShapeRef.new(shape: ScanRange, location_name: "ScanRange"))
    SelectObjectContentRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    SelectObjectContentRequest.struct_class = Types::SelectObjectContentRequest

    SelectParameters.add_member(:input_serialization, Shapes::ShapeRef.new(shape: InputSerialization, required: true, location_name: "InputSerialization"))
    SelectParameters.add_member(:expression_type, Shapes::ShapeRef.new(shape: ExpressionType, required: true, location_name: "ExpressionType"))
    SelectParameters.add_member(:expression, Shapes::ShapeRef.new(shape: Expression, required: true, location_name: "Expression"))
    SelectParameters.add_member(:output_serialization, Shapes::ShapeRef.new(shape: OutputSerialization, required: true, location_name: "OutputSerialization"))
    SelectParameters.struct_class = Types::SelectParameters

    ServerSideEncryptionByDefault.add_member(:sse_algorithm, Shapes::ShapeRef.new(shape: ServerSideEncryption, required: true, location_name: "SSEAlgorithm"))
    ServerSideEncryptionByDefault.add_member(:kms_master_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location_name: "KMSMasterKeyID"))
    ServerSideEncryptionByDefault.struct_class = Types::ServerSideEncryptionByDefault

    ServerSideEncryptionConfiguration.add_member(:rules, Shapes::ShapeRef.new(shape: ServerSideEncryptionRules, required: true, location_name: "Rule"))
    ServerSideEncryptionConfiguration.struct_class = Types::ServerSideEncryptionConfiguration

    ServerSideEncryptionRule.add_member(:apply_server_side_encryption_by_default, Shapes::ShapeRef.new(shape: ServerSideEncryptionByDefault, location_name: "ApplyServerSideEncryptionByDefault"))
    ServerSideEncryptionRule.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location_name: "BucketKeyEnabled"))
    ServerSideEncryptionRule.struct_class = Types::ServerSideEncryptionRule

    ServerSideEncryptionRules.member = Shapes::ShapeRef.new(shape: ServerSideEncryptionRule)

    SourceSelectionCriteria.add_member(:sse_kms_encrypted_objects, Shapes::ShapeRef.new(shape: SseKmsEncryptedObjects, location_name: "SseKmsEncryptedObjects"))
    SourceSelectionCriteria.add_member(:replica_modifications, Shapes::ShapeRef.new(shape: ReplicaModifications, location_name: "ReplicaModifications"))
    SourceSelectionCriteria.struct_class = Types::SourceSelectionCriteria

    SseKmsEncryptedObjects.add_member(:status, Shapes::ShapeRef.new(shape: SseKmsEncryptedObjectsStatus, required: true, location_name: "Status"))
    SseKmsEncryptedObjects.struct_class = Types::SseKmsEncryptedObjects

    Stats.add_member(:bytes_scanned, Shapes::ShapeRef.new(shape: BytesScanned, location_name: "BytesScanned"))
    Stats.add_member(:bytes_processed, Shapes::ShapeRef.new(shape: BytesProcessed, location_name: "BytesProcessed"))
    Stats.add_member(:bytes_returned, Shapes::ShapeRef.new(shape: BytesReturned, location_name: "BytesReturned"))
    Stats.struct_class = Types::Stats

    StatsEvent.add_member(:details, Shapes::ShapeRef.new(shape: Stats, eventpayload: true, eventpayload_type: 'structure', location_name: "Details", metadata: {"eventpayload"=>true}))
    StatsEvent.struct_class = Types::StatsEvent

    StorageClassAnalysis.add_member(:data_export, Shapes::ShapeRef.new(shape: StorageClassAnalysisDataExport, location_name: "DataExport"))
    StorageClassAnalysis.struct_class = Types::StorageClassAnalysis

    StorageClassAnalysisDataExport.add_member(:output_schema_version, Shapes::ShapeRef.new(shape: StorageClassAnalysisSchemaVersion, required: true, location_name: "OutputSchemaVersion"))
    StorageClassAnalysisDataExport.add_member(:destination, Shapes::ShapeRef.new(shape: AnalyticsExportDestination, required: true, location_name: "Destination"))
    StorageClassAnalysisDataExport.struct_class = Types::StorageClassAnalysisDataExport

    Tag.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location_name: "Key"))
    Tag.add_member(:value, Shapes::ShapeRef.new(shape: Value, required: true, location_name: "Value"))
    Tag.struct_class = Types::Tag

    TagSet.member = Shapes::ShapeRef.new(shape: Tag, location_name: "Tag")

    Tagging.add_member(:tag_set, Shapes::ShapeRef.new(shape: TagSet, required: true, location_name: "TagSet"))
    Tagging.struct_class = Types::Tagging

    TargetGrant.add_member(:grantee, Shapes::ShapeRef.new(shape: Grantee, location_name: "Grantee"))
    TargetGrant.add_member(:permission, Shapes::ShapeRef.new(shape: BucketLogsPermission, location_name: "Permission"))
    TargetGrant.struct_class = Types::TargetGrant

    TargetGrants.member = Shapes::ShapeRef.new(shape: TargetGrant, location_name: "Grant")

    Tiering.add_member(:days, Shapes::ShapeRef.new(shape: IntelligentTieringDays, required: true, location_name: "Days"))
    Tiering.add_member(:access_tier, Shapes::ShapeRef.new(shape: IntelligentTieringAccessTier, required: true, location_name: "AccessTier"))
    Tiering.struct_class = Types::Tiering

    TieringList.member = Shapes::ShapeRef.new(shape: Tiering)

    TopicConfiguration.add_member(:id, Shapes::ShapeRef.new(shape: NotificationId, location_name: "Id"))
    TopicConfiguration.add_member(:topic_arn, Shapes::ShapeRef.new(shape: TopicArn, required: true, location_name: "Topic"))
    TopicConfiguration.add_member(:events, Shapes::ShapeRef.new(shape: EventList, required: true, location_name: "Event"))
    TopicConfiguration.add_member(:filter, Shapes::ShapeRef.new(shape: NotificationConfigurationFilter, location_name: "Filter"))
    TopicConfiguration.struct_class = Types::TopicConfiguration

    TopicConfigurationDeprecated.add_member(:id, Shapes::ShapeRef.new(shape: NotificationId, location_name: "Id"))
    TopicConfigurationDeprecated.add_member(:events, Shapes::ShapeRef.new(shape: EventList, location_name: "Event"))
    TopicConfigurationDeprecated.add_member(:event, Shapes::ShapeRef.new(shape: Event, deprecated: true, location_name: "Event"))
    TopicConfigurationDeprecated.add_member(:topic, Shapes::ShapeRef.new(shape: TopicArn, location_name: "Topic"))
    TopicConfigurationDeprecated.struct_class = Types::TopicConfigurationDeprecated

    TopicConfigurationList.member = Shapes::ShapeRef.new(shape: TopicConfiguration)

    Transition.add_member(:date, Shapes::ShapeRef.new(shape: Date, location_name: "Date"))
    Transition.add_member(:days, Shapes::ShapeRef.new(shape: Days, location_name: "Days"))
    Transition.add_member(:storage_class, Shapes::ShapeRef.new(shape: TransitionStorageClass, location_name: "StorageClass"))
    Transition.struct_class = Types::Transition

    TransitionList.member = Shapes::ShapeRef.new(shape: Transition)

    UploadPartCopyOutput.add_member(:copy_source_version_id, Shapes::ShapeRef.new(shape: CopySourceVersionId, location: "header", location_name: "x-amz-copy-source-version-id"))
    UploadPartCopyOutput.add_member(:copy_part_result, Shapes::ShapeRef.new(shape: CopyPartResult, location_name: "CopyPartResult"))
    UploadPartCopyOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    UploadPartCopyOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    UploadPartCopyOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    UploadPartCopyOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    UploadPartCopyOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    UploadPartCopyOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    UploadPartCopyOutput.struct_class = Types::UploadPartCopyOutput
    UploadPartCopyOutput[:payload] = :copy_part_result
    UploadPartCopyOutput[:payload_member] = UploadPartCopyOutput.member(:copy_part_result)

    UploadPartCopyRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    UploadPartCopyRequest.add_member(:copy_source, Shapes::ShapeRef.new(shape: CopySource, required: true, location: "header", location_name: "x-amz-copy-source"))
    UploadPartCopyRequest.add_member(:copy_source_if_match, Shapes::ShapeRef.new(shape: CopySourceIfMatch, location: "header", location_name: "x-amz-copy-source-if-match"))
    UploadPartCopyRequest.add_member(:copy_source_if_modified_since, Shapes::ShapeRef.new(shape: CopySourceIfModifiedSince, location: "header", location_name: "x-amz-copy-source-if-modified-since"))
    UploadPartCopyRequest.add_member(:copy_source_if_none_match, Shapes::ShapeRef.new(shape: CopySourceIfNoneMatch, location: "header", location_name: "x-amz-copy-source-if-none-match"))
    UploadPartCopyRequest.add_member(:copy_source_if_unmodified_since, Shapes::ShapeRef.new(shape: CopySourceIfUnmodifiedSince, location: "header", location_name: "x-amz-copy-source-if-unmodified-since"))
    UploadPartCopyRequest.add_member(:copy_source_range, Shapes::ShapeRef.new(shape: CopySourceRange, location: "header", location_name: "x-amz-copy-source-range"))
    UploadPartCopyRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    UploadPartCopyRequest.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, required: true, location: "querystring", location_name: "partNumber"))
    UploadPartCopyRequest.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, required: true, location: "querystring", location_name: "uploadId"))
    UploadPartCopyRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    UploadPartCopyRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    UploadPartCopyRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    UploadPartCopyRequest.add_member(:copy_source_sse_customer_algorithm, Shapes::ShapeRef.new(shape: CopySourceSSECustomerAlgorithm, location: "header", location_name: "x-amz-copy-source-server-side-encryption-customer-algorithm"))
    UploadPartCopyRequest.add_member(:copy_source_sse_customer_key, Shapes::ShapeRef.new(shape: CopySourceSSECustomerKey, location: "header", location_name: "x-amz-copy-source-server-side-encryption-customer-key"))
    UploadPartCopyRequest.add_member(:copy_source_sse_customer_key_md5, Shapes::ShapeRef.new(shape: CopySourceSSECustomerKeyMD5, location: "header", location_name: "x-amz-copy-source-server-side-encryption-customer-key-MD5"))
    UploadPartCopyRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    UploadPartCopyRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    UploadPartCopyRequest.add_member(:expected_source_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-source-expected-bucket-owner"))
    UploadPartCopyRequest.struct_class = Types::UploadPartCopyRequest

    UploadPartOutput.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-server-side-encryption"))
    UploadPartOutput.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location: "header", location_name: "ETag"))
    UploadPartOutput.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    UploadPartOutput.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    UploadPartOutput.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    UploadPartOutput.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    UploadPartOutput.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    UploadPartOutput.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    UploadPartOutput.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-server-side-encryption-aws-kms-key-id"))
    UploadPartOutput.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-server-side-encryption-bucket-key-enabled"))
    UploadPartOutput.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-request-charged"))
    UploadPartOutput.struct_class = Types::UploadPartOutput

    UploadPartRequest.add_member(:body, Shapes::ShapeRef.new(shape: Body, location_name: "Body", metadata: {"streaming"=>true}))
    UploadPartRequest.add_member(:bucket, Shapes::ShapeRef.new(shape: BucketName, required: true, location: "uri", location_name: "Bucket", metadata: {"contextParam"=>{"name"=>"Bucket"}}))
    UploadPartRequest.add_member(:content_length, Shapes::ShapeRef.new(shape: ContentLength, location: "header", location_name: "Content-Length"))
    UploadPartRequest.add_member(:content_md5, Shapes::ShapeRef.new(shape: ContentMD5, location: "header", location_name: "Content-MD5"))
    UploadPartRequest.add_member(:checksum_algorithm, Shapes::ShapeRef.new(shape: ChecksumAlgorithm, location: "header", location_name: "x-amz-sdk-checksum-algorithm"))
    UploadPartRequest.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-checksum-crc32"))
    UploadPartRequest.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-checksum-crc32c"))
    UploadPartRequest.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-checksum-sha1"))
    UploadPartRequest.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-checksum-sha256"))
    UploadPartRequest.add_member(:key, Shapes::ShapeRef.new(shape: ObjectKey, required: true, location: "uri", location_name: "Key"))
    UploadPartRequest.add_member(:part_number, Shapes::ShapeRef.new(shape: PartNumber, required: true, location: "querystring", location_name: "partNumber"))
    UploadPartRequest.add_member(:upload_id, Shapes::ShapeRef.new(shape: MultipartUploadId, required: true, location: "querystring", location_name: "uploadId"))
    UploadPartRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-server-side-encryption-customer-algorithm"))
    UploadPartRequest.add_member(:sse_customer_key, Shapes::ShapeRef.new(shape: SSECustomerKey, location: "header", location_name: "x-amz-server-side-encryption-customer-key"))
    UploadPartRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-server-side-encryption-customer-key-MD5"))
    UploadPartRequest.add_member(:request_payer, Shapes::ShapeRef.new(shape: RequestPayer, location: "header", location_name: "x-amz-request-payer"))
    UploadPartRequest.add_member(:expected_bucket_owner, Shapes::ShapeRef.new(shape: AccountId, location: "header", location_name: "x-amz-expected-bucket-owner"))
    UploadPartRequest.struct_class = Types::UploadPartRequest
    UploadPartRequest[:payload] = :body
    UploadPartRequest[:payload_member] = UploadPartRequest.member(:body)

    UserMetadata.member = Shapes::ShapeRef.new(shape: MetadataEntry, location_name: "MetadataEntry")

    VersioningConfiguration.add_member(:mfa_delete, Shapes::ShapeRef.new(shape: MFADelete, location_name: "MfaDelete"))
    VersioningConfiguration.add_member(:status, Shapes::ShapeRef.new(shape: BucketVersioningStatus, location_name: "Status"))
    VersioningConfiguration.struct_class = Types::VersioningConfiguration

    WebsiteConfiguration.add_member(:error_document, Shapes::ShapeRef.new(shape: ErrorDocument, location_name: "ErrorDocument"))
    WebsiteConfiguration.add_member(:index_document, Shapes::ShapeRef.new(shape: IndexDocument, location_name: "IndexDocument"))
    WebsiteConfiguration.add_member(:redirect_all_requests_to, Shapes::ShapeRef.new(shape: RedirectAllRequestsTo, location_name: "RedirectAllRequestsTo"))
    WebsiteConfiguration.add_member(:routing_rules, Shapes::ShapeRef.new(shape: RoutingRules, location_name: "RoutingRules"))
    WebsiteConfiguration.struct_class = Types::WebsiteConfiguration

    WriteGetObjectResponseRequest.add_member(:request_route, Shapes::ShapeRef.new(shape: RequestRoute, required: true, location: "header", location_name: "x-amz-request-route", metadata: {"hostLabel"=>true, "hostLabelName"=>"RequestRoute"}))
    WriteGetObjectResponseRequest.add_member(:request_token, Shapes::ShapeRef.new(shape: RequestToken, required: true, location: "header", location_name: "x-amz-request-token"))
    WriteGetObjectResponseRequest.add_member(:body, Shapes::ShapeRef.new(shape: Body, location_name: "Body", metadata: {"streaming"=>true}))
    WriteGetObjectResponseRequest.add_member(:status_code, Shapes::ShapeRef.new(shape: GetObjectResponseStatusCode, location: "header", location_name: "x-amz-fwd-status"))
    WriteGetObjectResponseRequest.add_member(:error_code, Shapes::ShapeRef.new(shape: ErrorCode, location: "header", location_name: "x-amz-fwd-error-code"))
    WriteGetObjectResponseRequest.add_member(:error_message, Shapes::ShapeRef.new(shape: ErrorMessage, location: "header", location_name: "x-amz-fwd-error-message"))
    WriteGetObjectResponseRequest.add_member(:accept_ranges, Shapes::ShapeRef.new(shape: AcceptRanges, location: "header", location_name: "x-amz-fwd-header-accept-ranges"))
    WriteGetObjectResponseRequest.add_member(:cache_control, Shapes::ShapeRef.new(shape: CacheControl, location: "header", location_name: "x-amz-fwd-header-Cache-Control"))
    WriteGetObjectResponseRequest.add_member(:content_disposition, Shapes::ShapeRef.new(shape: ContentDisposition, location: "header", location_name: "x-amz-fwd-header-Content-Disposition"))
    WriteGetObjectResponseRequest.add_member(:content_encoding, Shapes::ShapeRef.new(shape: ContentEncoding, location: "header", location_name: "x-amz-fwd-header-Content-Encoding"))
    WriteGetObjectResponseRequest.add_member(:content_language, Shapes::ShapeRef.new(shape: ContentLanguage, location: "header", location_name: "x-amz-fwd-header-Content-Language"))
    WriteGetObjectResponseRequest.add_member(:content_length, Shapes::ShapeRef.new(shape: ContentLength, location: "header", location_name: "Content-Length"))
    WriteGetObjectResponseRequest.add_member(:content_range, Shapes::ShapeRef.new(shape: ContentRange, location: "header", location_name: "x-amz-fwd-header-Content-Range"))
    WriteGetObjectResponseRequest.add_member(:content_type, Shapes::ShapeRef.new(shape: ContentType, location: "header", location_name: "x-amz-fwd-header-Content-Type"))
    WriteGetObjectResponseRequest.add_member(:checksum_crc32, Shapes::ShapeRef.new(shape: ChecksumCRC32, location: "header", location_name: "x-amz-fwd-header-x-amz-checksum-crc32"))
    WriteGetObjectResponseRequest.add_member(:checksum_crc32c, Shapes::ShapeRef.new(shape: ChecksumCRC32C, location: "header", location_name: "x-amz-fwd-header-x-amz-checksum-crc32c"))
    WriteGetObjectResponseRequest.add_member(:checksum_sha1, Shapes::ShapeRef.new(shape: ChecksumSHA1, location: "header", location_name: "x-amz-fwd-header-x-amz-checksum-sha1"))
    WriteGetObjectResponseRequest.add_member(:checksum_sha256, Shapes::ShapeRef.new(shape: ChecksumSHA256, location: "header", location_name: "x-amz-fwd-header-x-amz-checksum-sha256"))
    WriteGetObjectResponseRequest.add_member(:delete_marker, Shapes::ShapeRef.new(shape: DeleteMarker, location: "header", location_name: "x-amz-fwd-header-x-amz-delete-marker"))
    WriteGetObjectResponseRequest.add_member(:etag, Shapes::ShapeRef.new(shape: ETag, location: "header", location_name: "x-amz-fwd-header-ETag"))
    WriteGetObjectResponseRequest.add_member(:expires, Shapes::ShapeRef.new(shape: Expires, location: "header", location_name: "x-amz-fwd-header-Expires"))
    WriteGetObjectResponseRequest.add_member(:expiration, Shapes::ShapeRef.new(shape: Expiration, location: "header", location_name: "x-amz-fwd-header-x-amz-expiration"))
    WriteGetObjectResponseRequest.add_member(:last_modified, Shapes::ShapeRef.new(shape: LastModified, location: "header", location_name: "x-amz-fwd-header-Last-Modified"))
    WriteGetObjectResponseRequest.add_member(:missing_meta, Shapes::ShapeRef.new(shape: MissingMeta, location: "header", location_name: "x-amz-fwd-header-x-amz-missing-meta"))
    WriteGetObjectResponseRequest.add_member(:metadata, Shapes::ShapeRef.new(shape: Metadata, location: "headers", location_name: "x-amz-meta-"))
    WriteGetObjectResponseRequest.add_member(:object_lock_mode, Shapes::ShapeRef.new(shape: ObjectLockMode, location: "header", location_name: "x-amz-fwd-header-x-amz-object-lock-mode"))
    WriteGetObjectResponseRequest.add_member(:object_lock_legal_hold_status, Shapes::ShapeRef.new(shape: ObjectLockLegalHoldStatus, location: "header", location_name: "x-amz-fwd-header-x-amz-object-lock-legal-hold"))
    WriteGetObjectResponseRequest.add_member(:object_lock_retain_until_date, Shapes::ShapeRef.new(shape: ObjectLockRetainUntilDate, location: "header", location_name: "x-amz-fwd-header-x-amz-object-lock-retain-until-date"))
    WriteGetObjectResponseRequest.add_member(:parts_count, Shapes::ShapeRef.new(shape: PartsCount, location: "header", location_name: "x-amz-fwd-header-x-amz-mp-parts-count"))
    WriteGetObjectResponseRequest.add_member(:replication_status, Shapes::ShapeRef.new(shape: ReplicationStatus, location: "header", location_name: "x-amz-fwd-header-x-amz-replication-status"))
    WriteGetObjectResponseRequest.add_member(:request_charged, Shapes::ShapeRef.new(shape: RequestCharged, location: "header", location_name: "x-amz-fwd-header-x-amz-request-charged"))
    WriteGetObjectResponseRequest.add_member(:restore, Shapes::ShapeRef.new(shape: Restore, location: "header", location_name: "x-amz-fwd-header-x-amz-restore"))
    WriteGetObjectResponseRequest.add_member(:server_side_encryption, Shapes::ShapeRef.new(shape: ServerSideEncryption, location: "header", location_name: "x-amz-fwd-header-x-amz-server-side-encryption"))
    WriteGetObjectResponseRequest.add_member(:sse_customer_algorithm, Shapes::ShapeRef.new(shape: SSECustomerAlgorithm, location: "header", location_name: "x-amz-fwd-header-x-amz-server-side-encryption-customer-algorithm"))
    WriteGetObjectResponseRequest.add_member(:ssekms_key_id, Shapes::ShapeRef.new(shape: SSEKMSKeyId, location: "header", location_name: "x-amz-fwd-header-x-amz-server-side-encryption-aws-kms-key-id"))
    WriteGetObjectResponseRequest.add_member(:sse_customer_key_md5, Shapes::ShapeRef.new(shape: SSECustomerKeyMD5, location: "header", location_name: "x-amz-fwd-header-x-amz-server-side-encryption-customer-key-MD5"))
    WriteGetObjectResponseRequest.add_member(:storage_class, Shapes::ShapeRef.new(shape: StorageClass, location: "header", location_name: "x-amz-fwd-header-x-amz-storage-class"))
    WriteGetObjectResponseRequest.add_member(:tag_count, Shapes::ShapeRef.new(shape: TagCount, location: "header", location_name: "x-amz-fwd-header-x-amz-tagging-count"))
    WriteGetObjectResponseRequest.add_member(:version_id, Shapes::ShapeRef.new(shape: ObjectVersionId, location: "header", location_name: "x-amz-fwd-header-x-amz-version-id"))
    WriteGetObjectResponseRequest.add_member(:bucket_key_enabled, Shapes::ShapeRef.new(shape: BucketKeyEnabled, location: "header", location_name: "x-amz-fwd-header-x-amz-server-side-encryption-bucket-key-enabled"))
    WriteGetObjectResponseRequest.struct_class = Types::WriteGetObjectResponseRequest
    WriteGetObjectResponseRequest[:payload] = :body
    WriteGetObjectResponseRequest[:payload_member] = WriteGetObjectResponseRequest.member(:body)


    # @api private
    API = Seahorse::Model::Api.new.tap do |api|

      api.version = "2006-03-01"

      api.metadata = {
        "apiVersion" => "2006-03-01",
        "checksumFormat" => "md5",
        "endpointPrefix" => "s3",
        "globalEndpoint" => "s3.amazonaws.com",
        "protocol" => "rest-xml",
        "serviceAbbreviation" => "Amazon S3",
        "serviceFullName" => "Amazon Simple Storage Service",
        "serviceId" => "S3",
        "uid" => "s3-2006-03-01",
      }

      api.add_operation(:abort_multipart_upload, Seahorse::Model::Operation.new.tap do |o|
        o.name = "AbortMultipartUpload"
        o.http_method = "DELETE"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: AbortMultipartUploadRequest)
        o.output = Shapes::ShapeRef.new(shape: AbortMultipartUploadOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchUpload)
      end)

      api.add_operation(:complete_multipart_upload, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CompleteMultipartUpload"
        o.http_method = "POST"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: CompleteMultipartUploadRequest)
        o.output = Shapes::ShapeRef.new(shape: CompleteMultipartUploadOutput)
      end)

      api.add_operation(:copy_object, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CopyObject"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: CopyObjectRequest)
        o.output = Shapes::ShapeRef.new(shape: CopyObjectOutput)
        o.errors << Shapes::ShapeRef.new(shape: ObjectNotInActiveTierError)
      end)

      api.add_operation(:create_bucket, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateBucket"
        o.http_method = "PUT"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: CreateBucketRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateBucketOutput)
        o.errors << Shapes::ShapeRef.new(shape: BucketAlreadyExists)
        o.errors << Shapes::ShapeRef.new(shape: BucketAlreadyOwnedByYou)
      end)

      api.add_operation(:create_multipart_upload, Seahorse::Model::Operation.new.tap do |o|
        o.name = "CreateMultipartUpload"
        o.http_method = "POST"
        o.http_request_uri = "/{Key+}?uploads"
        o.input = Shapes::ShapeRef.new(shape: CreateMultipartUploadRequest)
        o.output = Shapes::ShapeRef.new(shape: CreateMultipartUploadOutput)
      end)

      api.add_operation(:delete_bucket, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucket"
        o.http_method = "DELETE"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_analytics_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketAnalyticsConfiguration"
        o.http_method = "DELETE"
        o.http_request_uri = "/?analytics"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketAnalyticsConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_cors, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketCors"
        o.http_method = "DELETE"
        o.http_request_uri = "/?cors"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketCorsRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_encryption, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketEncryption"
        o.http_method = "DELETE"
        o.http_request_uri = "/?encryption"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketEncryptionRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_intelligent_tiering_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketIntelligentTieringConfiguration"
        o.http_method = "DELETE"
        o.http_request_uri = "/?intelligent-tiering"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketIntelligentTieringConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_inventory_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketInventoryConfiguration"
        o.http_method = "DELETE"
        o.http_request_uri = "/?inventory"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketInventoryConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_lifecycle, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketLifecycle"
        o.http_method = "DELETE"
        o.http_request_uri = "/?lifecycle"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketLifecycleRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_metrics_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketMetricsConfiguration"
        o.http_method = "DELETE"
        o.http_request_uri = "/?metrics"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketMetricsConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_ownership_controls, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketOwnershipControls"
        o.http_method = "DELETE"
        o.http_request_uri = "/?ownershipControls"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketOwnershipControlsRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketPolicy"
        o.http_method = "DELETE"
        o.http_request_uri = "/?policy"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_replication, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketReplication"
        o.http_method = "DELETE"
        o.http_request_uri = "/?replication"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketReplicationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_tagging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketTagging"
        o.http_method = "DELETE"
        o.http_request_uri = "/?tagging"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketTaggingRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_bucket_website, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteBucketWebsite"
        o.http_method = "DELETE"
        o.http_request_uri = "/?website"
        o.input = Shapes::ShapeRef.new(shape: DeleteBucketWebsiteRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:delete_object, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteObject"
        o.http_method = "DELETE"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: DeleteObjectRequest)
        o.output = Shapes::ShapeRef.new(shape: DeleteObjectOutput)
      end)

      api.add_operation(:delete_object_tagging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteObjectTagging"
        o.http_method = "DELETE"
        o.http_request_uri = "/{Key+}?tagging"
        o.input = Shapes::ShapeRef.new(shape: DeleteObjectTaggingRequest)
        o.output = Shapes::ShapeRef.new(shape: DeleteObjectTaggingOutput)
      end)

      api.add_operation(:delete_objects, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeleteObjects"
        o.http_method = "POST"
        o.http_request_uri = "/?delete"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: DeleteObjectsRequest)
        o.output = Shapes::ShapeRef.new(shape: DeleteObjectsOutput)
      end)

      api.add_operation(:delete_public_access_block, Seahorse::Model::Operation.new.tap do |o|
        o.name = "DeletePublicAccessBlock"
        o.http_method = "DELETE"
        o.http_request_uri = "/?publicAccessBlock"
        o.input = Shapes::ShapeRef.new(shape: DeletePublicAccessBlockRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:get_bucket_accelerate_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketAccelerateConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?accelerate"
        o.input = Shapes::ShapeRef.new(shape: GetBucketAccelerateConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketAccelerateConfigurationOutput)
      end)

      api.add_operation(:get_bucket_acl, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketAcl"
        o.http_method = "GET"
        o.http_request_uri = "/?acl"
        o.input = Shapes::ShapeRef.new(shape: GetBucketAclRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketAclOutput)
      end)

      api.add_operation(:get_bucket_analytics_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketAnalyticsConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?analytics"
        o.input = Shapes::ShapeRef.new(shape: GetBucketAnalyticsConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketAnalyticsConfigurationOutput)
      end)

      api.add_operation(:get_bucket_cors, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketCors"
        o.http_method = "GET"
        o.http_request_uri = "/?cors"
        o.input = Shapes::ShapeRef.new(shape: GetBucketCorsRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketCorsOutput)
      end)

      api.add_operation(:get_bucket_encryption, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketEncryption"
        o.http_method = "GET"
        o.http_request_uri = "/?encryption"
        o.input = Shapes::ShapeRef.new(shape: GetBucketEncryptionRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketEncryptionOutput)
      end)

      api.add_operation(:get_bucket_intelligent_tiering_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketIntelligentTieringConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?intelligent-tiering"
        o.input = Shapes::ShapeRef.new(shape: GetBucketIntelligentTieringConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketIntelligentTieringConfigurationOutput)
      end)

      api.add_operation(:get_bucket_inventory_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketInventoryConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?inventory"
        o.input = Shapes::ShapeRef.new(shape: GetBucketInventoryConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketInventoryConfigurationOutput)
      end)

      api.add_operation(:get_bucket_lifecycle, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketLifecycle"
        o.http_method = "GET"
        o.http_request_uri = "/?lifecycle"
        o.deprecated = true
        o.input = Shapes::ShapeRef.new(shape: GetBucketLifecycleRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketLifecycleOutput)
      end)

      api.add_operation(:get_bucket_lifecycle_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketLifecycleConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?lifecycle"
        o.input = Shapes::ShapeRef.new(shape: GetBucketLifecycleConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketLifecycleConfigurationOutput)
      end)

      api.add_operation(:get_bucket_location, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketLocation"
        o.http_method = "GET"
        o.http_request_uri = "/?location"
        o.input = Shapes::ShapeRef.new(shape: GetBucketLocationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketLocationOutput)
      end)

      api.add_operation(:get_bucket_logging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketLogging"
        o.http_method = "GET"
        o.http_request_uri = "/?logging"
        o.input = Shapes::ShapeRef.new(shape: GetBucketLoggingRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketLoggingOutput)
      end)

      api.add_operation(:get_bucket_metrics_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketMetricsConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?metrics"
        o.input = Shapes::ShapeRef.new(shape: GetBucketMetricsConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketMetricsConfigurationOutput)
      end)

      api.add_operation(:get_bucket_notification, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketNotification"
        o.http_method = "GET"
        o.http_request_uri = "/?notification"
        o.deprecated = true
        o.input = Shapes::ShapeRef.new(shape: GetBucketNotificationConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: NotificationConfigurationDeprecated)
      end)

      api.add_operation(:get_bucket_notification_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketNotificationConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?notification"
        o.input = Shapes::ShapeRef.new(shape: GetBucketNotificationConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: NotificationConfiguration)
      end)

      api.add_operation(:get_bucket_ownership_controls, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketOwnershipControls"
        o.http_method = "GET"
        o.http_request_uri = "/?ownershipControls"
        o.input = Shapes::ShapeRef.new(shape: GetBucketOwnershipControlsRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketOwnershipControlsOutput)
      end)

      api.add_operation(:get_bucket_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketPolicy"
        o.http_method = "GET"
        o.http_request_uri = "/?policy"
        o.input = Shapes::ShapeRef.new(shape: GetBucketPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketPolicyOutput)
      end)

      api.add_operation(:get_bucket_policy_status, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketPolicyStatus"
        o.http_method = "GET"
        o.http_request_uri = "/?policyStatus"
        o.input = Shapes::ShapeRef.new(shape: GetBucketPolicyStatusRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketPolicyStatusOutput)
      end)

      api.add_operation(:get_bucket_replication, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketReplication"
        o.http_method = "GET"
        o.http_request_uri = "/?replication"
        o.input = Shapes::ShapeRef.new(shape: GetBucketReplicationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketReplicationOutput)
      end)

      api.add_operation(:get_bucket_request_payment, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketRequestPayment"
        o.http_method = "GET"
        o.http_request_uri = "/?requestPayment"
        o.input = Shapes::ShapeRef.new(shape: GetBucketRequestPaymentRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketRequestPaymentOutput)
      end)

      api.add_operation(:get_bucket_tagging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketTagging"
        o.http_method = "GET"
        o.http_request_uri = "/?tagging"
        o.input = Shapes::ShapeRef.new(shape: GetBucketTaggingRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketTaggingOutput)
      end)

      api.add_operation(:get_bucket_versioning, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketVersioning"
        o.http_method = "GET"
        o.http_request_uri = "/?versioning"
        o.input = Shapes::ShapeRef.new(shape: GetBucketVersioningRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketVersioningOutput)
      end)

      api.add_operation(:get_bucket_website, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetBucketWebsite"
        o.http_method = "GET"
        o.http_request_uri = "/?website"
        o.input = Shapes::ShapeRef.new(shape: GetBucketWebsiteRequest)
        o.output = Shapes::ShapeRef.new(shape: GetBucketWebsiteOutput)
      end)

      api.add_operation(:get_object, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObject"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}"
        o.http_checksum = {
          "requestValidationModeMember" => "checksum_mode",
          "responseAlgorithms" => ["CRC32", "CRC32C", "SHA256", "SHA1"],
        }
        o.http_checksum = {
          "requestValidationModeMember" => "checksum_mode",
          "responseAlgorithms" => ["CRC32", "CRC32C", "SHA256", "SHA1"],
        }
        o.input = Shapes::ShapeRef.new(shape: GetObjectRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchKey)
        o.errors << Shapes::ShapeRef.new(shape: InvalidObjectState)
      end)

      api.add_operation(:get_object_acl, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectAcl"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}?acl"
        o.input = Shapes::ShapeRef.new(shape: GetObjectAclRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectAclOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchKey)
      end)

      api.add_operation(:get_object_attributes, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectAttributes"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}?attributes"
        o.input = Shapes::ShapeRef.new(shape: GetObjectAttributesRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectAttributesOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchKey)
      end)

      api.add_operation(:get_object_legal_hold, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectLegalHold"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}?legal-hold"
        o.input = Shapes::ShapeRef.new(shape: GetObjectLegalHoldRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectLegalHoldOutput)
      end)

      api.add_operation(:get_object_lock_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectLockConfiguration"
        o.http_method = "GET"
        o.http_request_uri = "/?object-lock"
        o.input = Shapes::ShapeRef.new(shape: GetObjectLockConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectLockConfigurationOutput)
      end)

      api.add_operation(:get_object_retention, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectRetention"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}?retention"
        o.input = Shapes::ShapeRef.new(shape: GetObjectRetentionRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectRetentionOutput)
      end)

      api.add_operation(:get_object_tagging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectTagging"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}?tagging"
        o.input = Shapes::ShapeRef.new(shape: GetObjectTaggingRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectTaggingOutput)
      end)

      api.add_operation(:get_object_torrent, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetObjectTorrent"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}?torrent"
        o.input = Shapes::ShapeRef.new(shape: GetObjectTorrentRequest)
        o.output = Shapes::ShapeRef.new(shape: GetObjectTorrentOutput)
      end)

      api.add_operation(:get_public_access_block, Seahorse::Model::Operation.new.tap do |o|
        o.name = "GetPublicAccessBlock"
        o.http_method = "GET"
        o.http_request_uri = "/?publicAccessBlock"
        o.input = Shapes::ShapeRef.new(shape: GetPublicAccessBlockRequest)
        o.output = Shapes::ShapeRef.new(shape: GetPublicAccessBlockOutput)
      end)

      api.add_operation(:head_bucket, Seahorse::Model::Operation.new.tap do |o|
        o.name = "HeadBucket"
        o.http_method = "HEAD"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: HeadBucketRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.errors << Shapes::ShapeRef.new(shape: NoSuchBucket)
      end)

      api.add_operation(:head_object, Seahorse::Model::Operation.new.tap do |o|
        o.name = "HeadObject"
        o.http_method = "HEAD"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: HeadObjectRequest)
        o.output = Shapes::ShapeRef.new(shape: HeadObjectOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchKey)
      end)

      api.add_operation(:list_bucket_analytics_configurations, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListBucketAnalyticsConfigurations"
        o.http_method = "GET"
        o.http_request_uri = "/?analytics"
        o.input = Shapes::ShapeRef.new(shape: ListBucketAnalyticsConfigurationsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListBucketAnalyticsConfigurationsOutput)
      end)

      api.add_operation(:list_bucket_intelligent_tiering_configurations, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListBucketIntelligentTieringConfigurations"
        o.http_method = "GET"
        o.http_request_uri = "/?intelligent-tiering"
        o.input = Shapes::ShapeRef.new(shape: ListBucketIntelligentTieringConfigurationsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListBucketIntelligentTieringConfigurationsOutput)
      end)

      api.add_operation(:list_bucket_inventory_configurations, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListBucketInventoryConfigurations"
        o.http_method = "GET"
        o.http_request_uri = "/?inventory"
        o.input = Shapes::ShapeRef.new(shape: ListBucketInventoryConfigurationsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListBucketInventoryConfigurationsOutput)
      end)

      api.add_operation(:list_bucket_metrics_configurations, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListBucketMetricsConfigurations"
        o.http_method = "GET"
        o.http_request_uri = "/?metrics"
        o.input = Shapes::ShapeRef.new(shape: ListBucketMetricsConfigurationsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListBucketMetricsConfigurationsOutput)
      end)

      api.add_operation(:list_buckets, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListBuckets"
        o.http_method = "GET"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
        o.output = Shapes::ShapeRef.new(shape: ListBucketsOutput)
      end)

      api.add_operation(:list_multipart_uploads, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListMultipartUploads"
        o.http_method = "GET"
        o.http_request_uri = "/?uploads"
        o.input = Shapes::ShapeRef.new(shape: ListMultipartUploadsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListMultipartUploadsOutput)
        o[:pager] = Aws::Pager.new(
          more_results: "is_truncated",
          limit_key: "max_uploads",
          tokens: {
            "next_key_marker" => "key_marker",
            "next_upload_id_marker" => "upload_id_marker"
          }
        )
      end)

      api.add_operation(:list_object_versions, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListObjectVersions"
        o.http_method = "GET"
        o.http_request_uri = "/?versions"
        o.input = Shapes::ShapeRef.new(shape: ListObjectVersionsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListObjectVersionsOutput)
        o[:pager] = Aws::Pager.new(
          more_results: "is_truncated",
          limit_key: "max_keys",
          tokens: {
            "next_key_marker" => "key_marker",
            "next_version_id_marker" => "version_id_marker"
          }
        )
      end)

      api.add_operation(:list_objects, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListObjects"
        o.http_method = "GET"
        o.http_request_uri = "/"
        o.input = Shapes::ShapeRef.new(shape: ListObjectsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListObjectsOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchBucket)
        o[:pager] = Aws::Pager.new(
          more_results: "is_truncated",
          limit_key: "max_keys",
          tokens: {
            "next_marker || contents[-1].key" => "marker"
          }
        )
      end)

      api.add_operation(:list_objects_v2, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListObjectsV2"
        o.http_method = "GET"
        o.http_request_uri = "/?list-type=2"
        o.input = Shapes::ShapeRef.new(shape: ListObjectsV2Request)
        o.output = Shapes::ShapeRef.new(shape: ListObjectsV2Output)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchBucket)
        o[:pager] = Aws::Pager.new(
          limit_key: "max_keys",
          tokens: {
            "next_continuation_token" => "continuation_token"
          }
        )
      end)

      api.add_operation(:list_parts, Seahorse::Model::Operation.new.tap do |o|
        o.name = "ListParts"
        o.http_method = "GET"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: ListPartsRequest)
        o.output = Shapes::ShapeRef.new(shape: ListPartsOutput)
        o[:pager] = Aws::Pager.new(
          more_results: "is_truncated",
          limit_key: "max_parts",
          tokens: {
            "next_part_number_marker" => "part_number_marker"
          }
        )
      end)

      api.add_operation(:put_bucket_accelerate_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketAccelerateConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?accelerate"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketAccelerateConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_acl, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketAcl"
        o.http_method = "PUT"
        o.http_request_uri = "/?acl"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketAclRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_analytics_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketAnalyticsConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?analytics"
        o.input = Shapes::ShapeRef.new(shape: PutBucketAnalyticsConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_cors, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketCors"
        o.http_method = "PUT"
        o.http_request_uri = "/?cors"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketCorsRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_encryption, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketEncryption"
        o.http_method = "PUT"
        o.http_request_uri = "/?encryption"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketEncryptionRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_intelligent_tiering_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketIntelligentTieringConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?intelligent-tiering"
        o.input = Shapes::ShapeRef.new(shape: PutBucketIntelligentTieringConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_inventory_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketInventoryConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?inventory"
        o.input = Shapes::ShapeRef.new(shape: PutBucketInventoryConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_lifecycle, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketLifecycle"
        o.http_method = "PUT"
        o.http_request_uri = "/?lifecycle"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.deprecated = true
        o.input = Shapes::ShapeRef.new(shape: PutBucketLifecycleRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_lifecycle_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketLifecycleConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?lifecycle"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketLifecycleConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_logging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketLogging"
        o.http_method = "PUT"
        o.http_request_uri = "/?logging"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketLoggingRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_metrics_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketMetricsConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?metrics"
        o.input = Shapes::ShapeRef.new(shape: PutBucketMetricsConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_notification, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketNotification"
        o.http_method = "PUT"
        o.http_request_uri = "/?notification"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.deprecated = true
        o.input = Shapes::ShapeRef.new(shape: PutBucketNotificationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_notification_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketNotificationConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?notification"
        o.input = Shapes::ShapeRef.new(shape: PutBucketNotificationConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_ownership_controls, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketOwnershipControls"
        o.http_method = "PUT"
        o.http_request_uri = "/?ownershipControls"
        o.http_checksum = {
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketOwnershipControlsRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_policy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketPolicy"
        o.http_method = "PUT"
        o.http_request_uri = "/?policy"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketPolicyRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_replication, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketReplication"
        o.http_method = "PUT"
        o.http_request_uri = "/?replication"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketReplicationRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_request_payment, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketRequestPayment"
        o.http_method = "PUT"
        o.http_request_uri = "/?requestPayment"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketRequestPaymentRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_tagging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketTagging"
        o.http_method = "PUT"
        o.http_request_uri = "/?tagging"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketTaggingRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_versioning, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketVersioning"
        o.http_method = "PUT"
        o.http_request_uri = "/?versioning"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketVersioningRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_bucket_website, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutBucketWebsite"
        o.http_method = "PUT"
        o.http_request_uri = "/?website"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutBucketWebsiteRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:put_object, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutObject"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.input = Shapes::ShapeRef.new(shape: PutObjectRequest)
        o.output = Shapes::ShapeRef.new(shape: PutObjectOutput)
      end)

      api.add_operation(:put_object_acl, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutObjectAcl"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}?acl"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutObjectAclRequest)
        o.output = Shapes::ShapeRef.new(shape: PutObjectAclOutput)
        o.errors << Shapes::ShapeRef.new(shape: NoSuchKey)
      end)

      api.add_operation(:put_object_legal_hold, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutObjectLegalHold"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}?legal-hold"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutObjectLegalHoldRequest)
        o.output = Shapes::ShapeRef.new(shape: PutObjectLegalHoldOutput)
      end)

      api.add_operation(:put_object_lock_configuration, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutObjectLockConfiguration"
        o.http_method = "PUT"
        o.http_request_uri = "/?object-lock"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutObjectLockConfigurationRequest)
        o.output = Shapes::ShapeRef.new(shape: PutObjectLockConfigurationOutput)
      end)

      api.add_operation(:put_object_retention, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutObjectRetention"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}?retention"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutObjectRetentionRequest)
        o.output = Shapes::ShapeRef.new(shape: PutObjectRetentionOutput)
      end)

      api.add_operation(:put_object_tagging, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutObjectTagging"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}?tagging"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutObjectTaggingRequest)
        o.output = Shapes::ShapeRef.new(shape: PutObjectTaggingOutput)
      end)

      api.add_operation(:put_public_access_block, Seahorse::Model::Operation.new.tap do |o|
        o.name = "PutPublicAccessBlock"
        o.http_method = "PUT"
        o.http_request_uri = "/?publicAccessBlock"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => true,
        }
        o.input = Shapes::ShapeRef.new(shape: PutPublicAccessBlockRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)

      api.add_operation(:restore_object, Seahorse::Model::Operation.new.tap do |o|
        o.name = "RestoreObject"
        o.http_method = "POST"
        o.http_request_uri = "/{Key+}?restore"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.input = Shapes::ShapeRef.new(shape: RestoreObjectRequest)
        o.output = Shapes::ShapeRef.new(shape: RestoreObjectOutput)
        o.errors << Shapes::ShapeRef.new(shape: ObjectAlreadyInActiveTierError)
      end)

      api.add_operation(:select_object_content, Seahorse::Model::Operation.new.tap do |o|
        o.name = "SelectObjectContent"
        o.http_method = "POST"
        o.http_request_uri = "/{Key+}?select&select-type=2"
        o.input = Shapes::ShapeRef.new(shape: SelectObjectContentRequest,
          location_name: "SelectObjectContentRequest",
          metadata: {
            "xmlNamespace" => {"uri"=>"http://s3.amazonaws.com/doc/2006-03-01/"}
          }
        )
        o.output = Shapes::ShapeRef.new(shape: SelectObjectContentOutput)
      end)

      api.add_operation(:upload_part, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UploadPart"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}"
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.http_checksum = {
          "requestAlgorithmMember" => "checksum_algorithm",
          "requestChecksumRequired" => false,
        }
        o.input = Shapes::ShapeRef.new(shape: UploadPartRequest)
        o.output = Shapes::ShapeRef.new(shape: UploadPartOutput)
      end)

      api.add_operation(:upload_part_copy, Seahorse::Model::Operation.new.tap do |o|
        o.name = "UploadPartCopy"
        o.http_method = "PUT"
        o.http_request_uri = "/{Key+}"
        o.input = Shapes::ShapeRef.new(shape: UploadPartCopyRequest)
        o.output = Shapes::ShapeRef.new(shape: UploadPartCopyOutput)
      end)

      api.add_operation(:write_get_object_response, Seahorse::Model::Operation.new.tap do |o|
        o.name = "WriteGetObjectResponse"
        o.http_method = "POST"
        o.http_request_uri = "/WriteGetObjectResponse"
        o['authtype'] = "v4-unsigned-body"
        o.endpoint_pattern = {
          "hostPrefix" => "{RequestRoute}.",
        }
        o.input = Shapes::ShapeRef.new(shape: WriteGetObjectResponseRequest)
        o.output = Shapes::ShapeRef.new(shape: Shapes::StructureShape.new(struct_class: Aws::EmptyStructure))
      end)
    end

  end
end
