Unreleased Changes
------------------

1.64.0 (2023-05-01)
------------------

* Feature - This release makes the NitroEnclave request parameter Recipient and the response field for CiphertextForRecipient available in AWS SDKs. It also adds the regex pattern for CloudHsmClusterId validation.

1.63.0 (2023-02-28)
------------------

* Feature - AWS KMS is deprecating the RSAES_PKCS1_V1_5 wrapping algorithm option in the GetParametersForImport API that is used in the AWS KMS Import Key Material feature. AWS KMS will end support for this wrapping algorithm by October 1, 2023.

1.62.0 (2023-01-18)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

* Issue - Replace runtime endpoint resolution approach with generated ruby code.

1.61.0 (2022-12-07)
------------------

* Feature - Updated examples and exceptions for External Key Store (XKS).

1.60.0 (2022-11-29)
------------------

* Feature - AWS KMS introduces the External Key Store (XKS), a new feature for customers who want to protect their data with encryption keys stored in an external key management system under their control.

1.59.0 (2022-10-25)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.58.0 (2022-07-18)
------------------

* Feature - Added support for the SM2 KeySpec in China Partition Regions

1.57.0 (2022-05-17)
------------------

* Feature - Add HMAC best practice tip, annual rotation of AWS managed keys.

1.56.0 (2022-04-19)
------------------

* Feature - Adds support for KMS keys and APIs that generate and verify HMAC codes

1.55.0 (2022-02-24)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.54.0 (2022-02-03)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.53.0 (2021-12-21)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.52.0 (2021-11-30)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.51.0 (2021-11-04)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.50.0 (2021-10-18)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.49.0 (2021-10-04)
------------------

* Feature - Added SDK examples for ConnectCustomKeyStore, CreateCustomKeyStore, CreateKey, DeleteCustomKeyStore, DescribeCustomKeyStores, DisconnectCustomKeyStore, GenerateDataKeyPair, GenerateDataKeyPairWithoutPlaintext, GetPublicKey, ReplicateKey, Sign, UpdateCustomKeyStore and Verify APIs

1.48.0 (2021-09-01)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.47.0 (2021-08-30)
------------------

* Feature - This release has changes to KMS nomenclature to remove the word master from both the "Customer master key" and "CMK" abbreviation and replace those naming conventions with "KMS key".

1.46.0 (2021-07-30)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.45.0 (2021-07-28)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.44.0 (2021-06-16)
------------------

* Feature - Adds support for multi-Region keys

1.43.0 (2021-03-10)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.42.0 (2021-02-02)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.41.0 (2021-01-11)
------------------

* Feature - Adds support for filtering grants by grant ID and grantee principal in ListGrants requests to AWS KMS.

1.40.0 (2020-12-17)
------------------

* Feature - Added CreationDate and LastUpdatedDate timestamps to ListAliases API response

1.39.0 (2020-09-30)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.38.0 (2020-09-15)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.37.0 (2020-08-25)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.36.0 (2020-07-02)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.35.0 (2020-06-23)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.34.1 (2020-06-11)
------------------

* Issue - Republish previous version with correct dependency on `aws-sdk-core`.

1.34.0 (2020-06-10)
------------------

* Issue - This version has been yanked. (#2327).
* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.33.0 (2020-06-01)
------------------

* Feature - AWS Key Management Service (AWS KMS): If the GenerateDataKeyPair or GenerateDataKeyPairWithoutPlaintext APIs are called on a CMK in a custom key store (origin == AWS_CLOUDHSM), they return an UnsupportedOperationException. If a call to UpdateAlias causes a customer to exceed the Alias resource quota, the UpdateAlias API returns a LimitExceededException.

1.32.0 (2020-05-28)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.31.0 (2020-05-07)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.30.0 (2020-03-09)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.29.0 (2020-02-10)
------------------

* Feature - The ConnectCustomKeyStore API now provides a new error code (SUBNET_NOT_FOUND) for customers to better troubleshoot if their "connect-custom-key-store" operation fails.

1.28.0 (2020-01-20)
------------------

* Feature - The ConnectCustomKeyStore operation now provides new error codes (USER_LOGGED_IN and USER_NOT_FOUND) for customers to better troubleshoot if their connect custom key store operation fails. Password length validation during CreateCustomKeyStore now also occurs on the client side.

1.27.0 (2019-12-09)
------------------

* Feature - The Verify operation now returns KMSInvalidSignatureException on invalid signatures. The Sign and Verify operations now return KMSInvalidStateException when a request is made against a CMK pending deletion.

1.26.0 (2019-11-25)
------------------

* Feature - AWS Key Management Service (KMS) now enables creation and use of asymmetric Customer Master Keys (CMKs) and the generation of asymmetric data key pairs.

1.25.0 (2019-10-23)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.24.0 (2019-07-25)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.23.0 (2019-07-01)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.22.0 (2019-06-17)
------------------

* Feature - Code Generated Changes, see `./build_tools` or `aws-sdk-core`'s CHANGELOG.md for details.

1.21.0 (2019-05-21)
------------------

* Feature - API update.

1.20.0 (2019-05-15)
------------------

* Feature - API update.

1.19.0 (2019-05-14)
------------------

* Feature - API update.

1.18.0 (2019-05-02)
------------------

* Feature - API update.

1.17.0 (2019-04-19)
------------------

* Feature - API update.

1.16.0 (2019-03-21)
------------------

* Feature - API update.

1.15.0 (2019-03-18)
------------------

* Feature - API update.

1.14.0 (2019-03-14)
------------------

* Feature - API update.

1.13.0 (2018-11-27)
------------------

* Feature - API update.

1.12.0 (2018-11-20)
------------------

* Feature - API update.

1.11.0 (2018-10-24)
------------------

* Feature - API update.

1.10.0 (2018-10-23)
------------------

* Feature - API update.

1.9.0 (2018-09-06)
------------------

* Feature - Adds code paths and plugins for future SDK instrumentation and telemetry.

1.8.0 (2018-09-05)
------------------

* Feature - API update.

1.7.0 (2018-07-31)
------------------

* Feature - API update.

1.6.0 (2018-06-26)
------------------

* Feature - API update.

1.5.0 (2018-02-12)
------------------

* Feature - API update.

1.4.0 (2018-01-09)
------------------

* Feature - API update.

1.3.0 (2017-11-07)
------------------

* Feature - API update.

1.2.0 (2017-09-13)
------------------

* Feature - API update.

1.1.0 (2017-09-06)
------------------

* Feature - API update.

* Issue - Compact long string in KMS shared examples causing hanging for jruby
* Issue - Update `aws-sdk-kms` gemspec metadata.

1.0.0 (2017-08-29)
------------------

1.0.0.rc13 (2017-08-15)
------------------

* Feature - API update.

1.0.0.rc12 (2017-08-01)
------------------

* Feature - API update.

1.0.0.rc11 (2017-07-25)
------------------

* Feature - API update.

1.0.0.rc10 (2017-07-13)
------------------

* Feature - API update.

1.0.0.rc9 (2017-07-06)
------------------

* Feature - API update.

1.0.0.rc8 (2017-06-29)
------------------

* Feature - API update.

1.0.0.rc7 (2017-05-23)
------------------

* Feature - API update.

1.0.0.rc6 (2017-05-09)
------------------

* Feature - API update.

1.0.0.rc5 (2017-05-09)
------------------

* Feature - API update.

1.0.0.rc4 (2017-04-21)
------------------

* Feature - API update.

1.0.0.rc3 (2017-03-07)
------------------

* Feature - API update.

1.0.0.rc2 (2017-01-24)
------------------

* Feature - API update.

1.0.0.rc1 (2016-12-05)
------------------

* Feature - Initial preview release of the `aws-sdk-kms` gem.
