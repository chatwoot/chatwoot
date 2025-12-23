# Release History

### 2.2.1 (2024-10-04)

#### Bug Fixes

* Fixed edge cases in token expiration extraction ([#73](https://github.com/googleapis/ruby-cloud-env/issues/73)) 

### 2.2.0 (2024-08-22)

#### Features

* Provide a query for whether a logging agent is expected in the current environment ([#70](https://github.com/googleapis/ruby-cloud-env/issues/70)) 
* Require Ruby 3.0 or later ([#71](https://github.com/googleapis/ruby-cloud-env/issues/71)) 

### 2.1.1 (2024-02-01)

#### Bug Fixes

* Setting non-empty overrides simulates metadata server existence setting ([#64](https://github.com/googleapis/ruby-cloud-env/issues/64)) 

### 2.1.0 (2023-12-12)

#### Features

* Provide retrieval_monotonic_time on compute metadata response objects ([#62](https://github.com/googleapis/ruby-cloud-env/issues/62)) 

### 2.0.1 (2023-12-01)

#### Bug Fixes

* Bad response status or flavor headers no longer signal positive metadata existence ([#61](https://github.com/googleapis/ruby-cloud-env/issues/61)) 
* Increase token expiry buffer to three and a half minutes ([#59](https://github.com/googleapis/ruby-cloud-env/issues/59)) 

### 2.0.0 (2023-11-14)

This is a major overhaul of the mechanisms underlying this gem, to improve reliability and provide better mocking interfaces. Environment interrogation calls are unchanged, but the mocking override parameters from 1.x have been removed in favor of the new interfaces, hence the semver-major version bump.

This version has not yet added explicit calls for detecting newer runtimes such as Cloud Run and Cloud Functions. Those will come in the near future.

#### Features

* Update minimum Ruby version to 2.7
* Provide access objects for information sources (such as environment variables, file system, and metadata server)
* Each access object has an interface for providing mock data for testing
* Much more robust retry policy and detection mechanisms for the metadata server
* Provide ensure_metadata and lookup_metadata_response calls at the top level interface

### 1.7.0 (2023-05-15)

#### Features

* Update minimum Ruby version to 2.6 ([#34](https://github.com/googleapis/ruby-cloud-env/issues/34)) 

### 1.6.0 (2022-03-21)

* Support for Faraday 2

### 1.5.0 (2021-03-08)

#### Features

* Drop support for Ruby 2.4 and add support for Ruby 3.0

### 1.4.0 / 2020-10-12

#### Features

* Honor GCE_METADATA_HOST environment variable

### 1.3.3 / 2020-07-10

#### Bug Fixes

* Project ID logic honors GOOGLE_CLOUD_PROJECT

### 1.3.2 / 2020-05-28

#### Documentation

* Fix a few broken links

### 1.3.1 / 2020-03-02

#### Bug Fixes

* support faraday 1.x

### 1.3.0 / 2019-10-23

Now requires Ruby 2.4 or later.

#### Features

* Recognize App Engine Standard and Knative

### 1.2.1 / 2019-08-23

#### Bug Fixes

* Send Metadata-Flavor header when testing the metadata server root

#### Documentation

* Update documentation

### 1.2.0 / 2019-06-19

* Support separate timeout for connecting to the metadata server vs the entire request

### 1.1.0 / 2019-05-29

* Support disabling of the metadata cache
* Support configurable retries when querying the metadata server
* Support configuration of the metadata request timeout

### 1.0.5 / 2018-09-20

* Update documentation.
  * Change documentation URL to googleapis GitHub org.

### 1.0.4 / 2018-09-12

* Add missing documentation files to package.

### 1.0.3 / 2018-09-10

* Update documentation.

### 1.0.2 / 2018-06-28

* Use Kubernetes Engine names.
  * Alias old method names for backwards compatibility.
* Handle EHOSTDOWN error when connecting to env.

### 1.0.1 / 2017-07-11

* Update gem spec homepage links.

### 1.0.0 / 2017-03-31

* Initial release
