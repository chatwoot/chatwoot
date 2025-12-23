# Release History

### 1.20.0 (2025-04-29)

#### Features

* Automated update of googleapis-common-protos-types ([#374](https://github.com/googleapis/common-protos-ruby/issues/374)) 
* drop ruby 3.0 from CI and update baseline types gems to 3.1 ([#375](https://github.com/googleapis/common-protos-ruby/issues/375)) 

### 1.19.0 (2025-03-13)

#### Features

* Automated update of googleapis-common-protos-types ([#351](https://github.com/googleapis/common-protos-ruby/issues/351)) 
* Update minimum required Ruby to 3.0 ([#354](https://github.com/googleapis/common-protos-ruby/issues/354)) 

### 1.18.0 (2025-01-14)

#### Features

* Added a few additional client generation settings 
* Added MetricDescriptorMetadata#time_series_resource_hierarchy_level 
* Added MISSING_ORIGIN and OVERLOADED_CREDENTIALS error reasons 
* Added reason and localized_message fields to FieldViolation 

### 1.17.0 (2025-01-09)

#### Features

* Added PythonSettings#experimental_features ([#336](https://github.com/googleapis/common-protos-ruby/issues/336)) 

### 1.16.0 (2024-09-11)

#### Features

* Added referenced types to Google::Api::FieldInfo 
#### Documentation

* Various improvements to reference documentation 

### 1.15.0 (2024-06-11)

#### Features

* Support for google-protobuf 4.x ([#315](https://github.com/googleapis/common-protos-ruby/issues/315)) 

### 1.14.0 (2024-03-16)

#### Features

* Added LOCATION_POLICY_VIOLATED as an error reason 
* Added rest_reference_documentation_uri to the Publishing config 
* Added the google.api.api_version service option 
#### Documentation

* Minor documentation updates 

### 1.13.0 (2024-02-23)

#### Features

* Update minimum Ruby version to 2.7 ([#246](https://github.com/googleapis/common-protos-ruby/issues/246)) 

### 1.12.0 (2024-02-13)

#### Features

* set packed to false on field_behavior extension ([#239](https://github.com/googleapis/common-protos-ruby/issues/239)) 

### 1.11.0 (2023-12-04)

#### Features

* Automated update of googleapis-common-protos-types ([#217](https://github.com/googleapis/common-protos-ruby/issues/217)) 

### 1.10.0 (2023-11-06)

#### Features

* Automated update of googleapis-common-protos-types ([#200](https://github.com/googleapis/common-protos-ruby/issues/200)) 

### 1.9.0 (2023-09-19)

#### Features

* Added the "IDENTIFIER" field behavior ([#181](https://github.com/googleapis/common-protos-ruby/issues/181)) 

### 1.8.0 (2023-08-07)

#### Features

* Support for API method policies ([#175](https://github.com/googleapis/common-protos-ruby/issues/175)) 
* Updated generated protobuf output to use binary descriptors for better future compatibility ([#165](https://github.com/googleapis/common-protos-ruby/issues/165)) 

### 1.7.0 (2023-07-16)

#### Features

* Support for a few additional client library organizations ([#141](https://github.com/googleapis/common-protos-ruby/issues/141)) 

### 1.6.0 (2023-04-24)

#### Features

* Added Google::Rpc::Context::AttributeContext
* Added Google::Rpc::Context::AuditContext
* Added dotnet-specific fields to API language settings
* Added overrides_by_request_protocol to api.BackendRule
* Added proto_reference_documentation_uri to api.Publishing
* Added SERVICE_NOT_VISIBLE and GCP_SUSPENDED error reason values

### 1.5.0 (2023-01-04)

#### Features

* Added "cookie" JwtLocation
* Added protos related to client library publishing
* Added several new error reasons
* Added protos describing HTTP requests and responses

### 1.4.0 (2022-08-17)

#### Features

* Update minimum Ruby version to 2.6 ([#75](https://github.com/googleapis/common-protos-ruby/issues/75)) 

### 1.3.2 (2022-06-23)

#### Bug Fixes

* Remove some unnecessary requires

### 1.3.1 (2022-04-05)

* Sync updates to imports in the source protos

### 1.3.0 (2021-10-19)

* Add google/api/routing to common-protos-types
* Remove cloud-specific extended_operations proto. It's being moved to google-cloud-common.

### 1.2.0 (2021-09-03)

* Add Google::Cloud::OperationResponseMapping and the extended_operations_pb file
* Removed unnecessary files from the gem package

### 1.1.0 / 2021-07-07

* Add Google::Api::ErrorReason
* Add Google::Api::Visibility and Google::Api::VisibilityRule
* Add Google::Type::Decimal
* Add NON_EMPTY_DEFAULT value to Google::Api::FieldBehavior.

### 1.0.6 / 2021-02-01

* Add Google::Type::Interval type.
* Add Google::Type::LocalizedText type.
* Add Google::Type::PhoneNumber and Google::Type::PhoneNumber::ShortCode types.
* Add "service_root_url" field to Google::Api::Documentation.
* Add UNORDERED_LIST value to Google::Api::FieldBehavior.
* Add UNIMPLEMENTED and PRELAUNCH values to Google::Api::LaunchStage.
* Add "monitored_resource_types" field to Google::Api::MetricDescriptor.
* Add Google::Api::ResourceDescriptor::Style type and add "style" field to Google::Api::ResourceDescriptor.
* Moved HttpRequest and LogSeverity types from Google::Logging::Type to Google::Cloud::Logging::Type, and created aliases for backward compatibility.
* Remove internal "features" field from Google::Api::Endpoint.
* Require protobuf 3.14.

### 1.0.5 / 2020-04-08

* Add JWT location support in Google::Api::AuthProvider.
* Add "protocol" field and a "disable_auth" option to Google::Api::BackendRule.
* Add "launch_stage" field to Google::Api::MetricDescriptor and Google::Api::MonitoredResourceDescriptor.
* Add Google::Api::ResourceDescriptor and Google::Api::ResourceReference types and remove obsolete Google::Api::Resource type.
* Remove obsolete "experimental" field from Google::Api::Service type.
* Add Google::Rpc::ErrorInfo type.
* Add Google::Type::DateTime, Google::Type::Month, and Google::Type::TimeZone types.
* Require protobuf 3.11.

### 1.0.4 / 2019-04-03

* Add WaitOperation RPC to operations_pb.rb and update documentation.
* Add new common types for:
  + google/api/resource.proto
  + google/type/calendar_period.proto
  + google/type/expr.proto
  + google/type/fraction.proto
  + google/type/quaternion.proto
