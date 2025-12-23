# Release History

### 0.20.0 (2023-08-31)

#### Features

* Add channel pooling for gapic clients ([#969](https://github.com/googleapis/gapic-generator-ruby/issues/969)) 
* Add LRU hash ([#970](https://github.com/googleapis/gapic-generator-ruby/issues/970)) 
#### Documentation

* Minor fixes to YARD documentation links and parameters ([#959](https://github.com/googleapis/gapic-generator-ruby/issues/959)) 

### 0.19.1 (2023-05-30)

#### Bug Fixes

* Fixed handling of optional fields in coerce ([#954](https://github.com/googleapis/gapic-generator-ruby/issues/954)) 

### 0.19.0 (2023-05-26)

#### Features

* Compatibility with protobuf v23 generated map fields ([#948](https://github.com/googleapis/gapic-generator-ruby/issues/948)) 

### 0.18.0 (2023-02-27)

#### Features

* add alias for details field in Rest Error ([#928](https://github.com/googleapis/gapic-generator-ruby/issues/928)) 

### 0.17.1 (2023-02-09)

#### Bug Fixes

* add new class to the rest imports ([#913](https://github.com/googleapis/gapic-generator-ruby/issues/913)) 

### 0.17.0 (2023-02-09)

#### Features

* add a transport operation class in Rest ([#911](https://github.com/googleapis/gapic-generator-ruby/issues/911)) 

### 0.16.0 (2022-12-12)

#### Features

* custom regapic exception wrapping ([#866](https://github.com/googleapis/gapic-generator-ruby/issues/866)) 

### 0.15.1 (2022-11-18)

#### Bug Fixes

* Fixed uninitialized constant when checking retry policy for a REST call ([#857](https://github.com/googleapis/gapic-generator-ruby/issues/857)) 

### 0.15.0 (2022-11-17)

#### Features

* retry policy now works for REST calls

### 0.14.0 (2022-11-08)

#### Features

* add support for different types of credentials to REST 
#### Bug Fixes

* deadlock fix ([#845](https://github.com/googleapis/gapic-generator-ruby/issues/845)) 

### 0.13.0 (2022-10-26)

#### Features

* Implement server-side streaming support for REST calls in gapic-common ([#826](https://github.com/googleapis/gapic-generator-ruby/issues/826)) 

### 0.12.0 (2022-09-15)

#### Features

* Support numeric_enums in the ClientStub ([#817](https://github.com/googleapis/gapic-generator-ruby/issues/817)) 
* parse details information from REST errors  ([#815](https://github.com/googleapis/gapic-generator-ruby/issues/815)) 
* send protobuf version in headers ([#816](https://github.com/googleapis/gapic-generator-ruby/issues/816)) 

#### Bug Fixes

* rewrap certain grpc errors ([#810](https://github.com/googleapis/gapic-generator-ruby/issues/810)) 
  This will rewrap some GRPC::Unavailable errors that were caused by authentication failing as Gapic::GRPC::AuthorizationError which inherits from ::GRPC::Unauthenticated

### 0.11.1 (2022-08-03)

#### Bug Fixes

* error code of 0 is not an error, body template field can be nil ([#805](https://github.com/googleapis/gapic-generator-ruby/issues/805)) 

### 0.11.0 (2022-07-27)

#### Features

* Add CallOptions#merge and CallOptions equality checking ([#802](https://github.com/googleapis/gapic-generator-ruby/issues/802)) 

#### Bug Fixes

* transcoder should always preserve slashes ([#795](https://github.com/googleapis/gapic-generator-ruby/issues/795)) 

### 0.10.0 (2022-06-20)

#### Features

* Require at least Ruby 2.6
* Support faraday 2.0
#### Bug Fixes

* Fix precision issues in protobuf timestamp conversion
* Fix some Ruby 3.0 keyword argument usage errors

### 0.9.0 (2022-05-18)

#### Features

* add full grpc transcoding to gapic-common
#### Bug Fixes

* small fixes for combined libraries and testing

### 0.8.0 / 2022-01-20

* Add generic LROs helpers. These are used for the Nonstandard (not conforming to AIP-151) Cloud LROs.

### 0.7.0 / 2021-08-03

* Require googleauth 0.17 for proper support of JWT credentials with custom scopes

### 0.6.0 / 2021-07-22

* Added helper for REST pagination

### 0.5.0 / 2021-06-15

* Provide a way to create `x-goog-api-client` headers with rest library version and/or without grpc library version

### 0.4.3 / 2021-06-10

* Fix file permissions.

### 0.4.2 / 2021-06-07

* Expand googleauth dependency to include 1.x
* Add a REST PUT method helper to Gapic::Rest.

### 0.4.1 / 2021-04-15

* Provide a default value for the 'body' in the REST POST method in Gapic::Rest.

### 0.4.0 / 2021-02-23

* Support for the REST calls via the Gapic::Rest::ClientStub and other classes in Gapic::Rest
  REST support is still being developed. Notably the full retries handling is not implemented yet.

### 0.3.4 / 2020-08-07

* Support the :this_channel_is_insecure gRPC pseudo-credential, used by tests and emulators.

### 0.3.3 / 2020-08-05

* Retry configs properly handle error name strings.

### 0.3.2 / 2020-07-30

* Alias PagedEnumerable#next_page to PagedEnumerable#next_page!

### 0.3.1 / 2020-06-19

* Fix file permissions

### 0.3.0 / 2020-06-18

* Update the dependency on google-protobuf to 3.12.2

### 0.2.1 / 2020-06-02

* Fix a crash when resetting a config field to nil when it has a parent but no default

### 0.2.0 / 2020-03-17

* Support default call options in Gapic::Operation
* Fix implicit kwarg warnings under Ruby 2.7

### 0.1.0 / 2020-01-09

Initial release
