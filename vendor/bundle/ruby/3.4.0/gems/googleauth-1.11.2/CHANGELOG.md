# Release History

### 1.11.2 (2024-10-23)

#### Bug Fixes

* Temporarily disable universe domain query from GCE metadata server ([#493](https://github.com/googleapis/google-auth-library-ruby/issues/493)) 
* Use updated metadata path for universe-domain ([#496](https://github.com/googleapis/google-auth-library-ruby/issues/496)) 

### 1.11.1 (2024-10-04)

#### Bug Fixes

* Fixed parsing of expiration timestamp from ID tokens ([#492](https://github.com/googleapis/google-auth-library-ruby/issues/492)) 
* Use NoMethodError instead of NotImplementedError for unimplemented base class methods ([#487](https://github.com/googleapis/google-auth-library-ruby/issues/487)) 

### 1.11.0 (2024-02-09)

#### Features

* Deprecate the positional argument for callback_uri, and introduce keyword argument instead ([#475](https://github.com/googleapis/google-auth-library-ruby/issues/475)) 

### 1.10.0 (2024-02-08)

#### Features

* add PKCE to 3 Legged OAuth exchange ([#471](https://github.com/googleapis/google-auth-library-ruby/issues/471)) 
#### Bug Fixes

* Client library credentials provide correct self-signed JWT and external account behavior when loading from a file path or JSON data ([#474](https://github.com/googleapis/google-auth-library-ruby/issues/474)) 
* Prioritize universe domain specified in GCECredentials arguments over metadata-fetched value ([#472](https://github.com/googleapis/google-auth-library-ruby/issues/472)) 

### 1.9.2 (2024-01-25)

#### Bug Fixes

* Prevent access tokens from being fetched at service account construction in the self-signed-jwt case ([#467](https://github.com/googleapis/google-auth-library-ruby/issues/467)) 

### 1.9.1 (2023-12-12)

#### Bug Fixes

* update expires_in for cached metadata-retrieved tokens ([#464](https://github.com/googleapis/google-auth-library-ruby/issues/464)) 

### 1.9.0 (2023-12-07)

#### Features

* Include universe_domain in credentials ([#460](https://github.com/googleapis/google-auth-library-ruby/issues/460)) 
* Use google-cloud-env for more robust Metadata Service access ([#459](https://github.com/googleapis/google-auth-library-ruby/issues/459)) 

### 1.8.1 (2023-09-19)

#### Documentation

* improve ADC related error and warning messages ([#452](https://github.com/googleapis/google-auth-library-ruby/issues/452)) 

### 1.8.0 (2023-09-07)

#### Features

* Pass additional parameters to auhtorization url ([#447](https://github.com/googleapis/google-auth-library-ruby/issues/447)) 
#### Documentation

* improve ADC related error and warning messages ([#449](https://github.com/googleapis/google-auth-library-ruby/issues/449)) 

### 1.7.0 (2023-07-14)

#### Features

* Adding support for pluggable auth credentials ([#437](https://github.com/googleapis/google-auth-library-ruby/issues/437)) 
#### Documentation

* fixed iss argument and description in comments of IDTokens ([#438](https://github.com/googleapis/google-auth-library-ruby/issues/438)) 

### 1.6.0 (2023-06-20)

#### Features

* adding identity pool credentials ([#433](https://github.com/googleapis/google-auth-library-ruby/issues/433)) 
#### Documentation

* deprecation message for discontinuing command line auth flow ([#435](https://github.com/googleapis/google-auth-library-ruby/issues/435)) 

### 1.5.2 (2023-04-13)

#### Bug Fixes

* AWS IMDSV2 session token fetching shall call PUT method instead of GET ([#429](https://github.com/googleapis/google-auth-library-ruby/issues/429)) 
* GCECredentials - Allow retrieval of ID token ([#425](https://github.com/googleapis/google-auth-library-ruby/issues/425)) 

### 1.5.1 (2023-04-10)

#### Bug Fixes

* Remove external account config validation ([#427](https://github.com/googleapis/google-auth-library-ruby/issues/427)) 

### 1.5.0 (2023-03-21)

#### Features

* Add support for AWS Workload Identity Federation ([#418](https://github.com/googleapis/google-auth-library-ruby/issues/418)) 

### 1.4.0 (2022-12-14)

#### Features

* make new_jwt_token public in order to fetch raw token directly ([#405](https://github.com/googleapis/google-auth-library-ruby/issues/405)) 

### 1.3.0 (2022-10-18)

#### Features

* Use OpenSSL 3.0 compatible interfaces for IDTokens ([#397](https://github.com/googleapis/google-auth-library-ruby/issues/397)) 

### 1.2.0 (2022-06-23)

* Updated minimum Ruby version to 2.6

### 1.1.3 (2022-04-20)

#### Documentation

* Add README instructions for 3-Legged OAuth with a service account

### 1.1.2 (2022-02-22)

#### Bug Fixes

* Support Faraday 2

### 1.1.1 (2022-02-14)

#### Bug Fixes

* add quota_project to user refresh credentials

### 1.1.0 (2021-10-24)

#### Features

* Support short-lived tokens in Credentials

### 1.0.0 (2021-09-27)

Bumped version to 1.0.0. Releases from this point will follow semver.

* Allow dependency on future 1.x versions of signet
* Prevented gcloud from authenticating on the console when getting the gcloud project

### 0.17.1 (2021-09-01)

* Updates to gem metadata

### 0.17.0 (2021-07-30)

* Allow scopes to be self-signed into jwts

### 0.16.2 (2021-04-28)

* Stop attempting to get the project from gcloud when applying self-signed JWTs

### 0.16.1 (2021-04-01)

* Accept application/text content-type for plain idtoken response

### 0.16.0 (2021-03-04)

* Drop support for Ruby 2.4 and add support for Ruby 3.0

### 0.15.1 (2021-02-08)

* Fix crash when using a client credential without any paths or env_vars set

### 0.15.0 (2021-01-26)

* Credential parameters inherit from superclasses
* Service accounts apply a self-signed JWT if scopes are marked as default
* Retry fetch_access_token when GCE metadata server returns unexpected errors
* Support correct service account and user refresh behavior for custom credential env variables

### 0.14.0 / 2020-10-09

* Honor GCE_METADATA_HOST environment variable
* Fix errors in some environments when requesting an access token for multiple scopes

### 0.13.1 / 2020-07-30

* Support scopes when using GCE Metadata Server authentication ([@ball-hayden][])

### 0.13.0 / 2020-06-17

* Support for validating ID tokens.
* Fixed header application of ID tokens from service accounts.

### 0.12.0 / 2020-04-08

* Support for ID token credentials.
* Support reading quota_id_project from service account credentials.

### 0.11.0 / 2020-02-24

* Support Faraday 1.x.
* Allow special "postmessage" value for redirect_uri.

### 0.10.0 / 2019-10-09

Note: This release now requires Ruby 2.4 or later

* Increase metadata timeout to improve reliability in some hosting environments
* Support an environment variable to suppress Cloud SDK credentials warnings
* Make the header check case insensitive
* Set instance variables at initialization to avoid spamming warnings
* Pass "Metadata-Flavor" header to metadata server when checking for GCE

### 0.9.0 / 2019-08-05

* Restore compatibility with Ruby 2.0. This is the last release that will work on end-of-lifed versions of Ruby. The 0.10 release will require Ruby 2.4 or later.
* Update Credentials to use methods for values that are intended to be changed by users, replacing constants.
* Add retry on error for fetch_access_token
* Allow specifying custom state key-values
* Add verbosity none to gcloud command
* Make arity of WebUserAuthorizer#get_credentials compatible with the base class

### 0.8.1 / 2019-03-27

* Silence unnecessary gcloud warning
* Treat empty credentials environment variables as unset

### 0.8.0 / 2019-01-02

* Support connection options :default_connection and :connection_builder when creating credentials that need to refresh OAuth tokens. This lets clients provide connection objects with custom settings, such as proxies, needed for the client environment.
* Removed an unnecessary warning about project IDs.

### 0.7.1 / 2018-10-25

* Make load_gcloud_project_id module function.

### 0.7.0 / 2018-10-24

* Add project_id instance variable to UserRefreshCredentials, ServiceAccountCredentials, and Credentials.

### 0.6.7 / 2018-10-16

* Update memoist dependency to ~> 0.16.

### 0.6.6 / 2018-08-22

* Remove ruby version warnings.

### 0.6.5 / 2018-08-16

* Fix incorrect http verb when revoking credentials.
* Warn on EOL ruby versions.

### 0.6.4 / 2018-08-03

* Resolve issue where DefaultCredentials constant was undefined.

### 0.6.3 / 2018-08-02

* Resolve issue where token_store was being written to twice

### 0.6.2 / 2018-08-01

* Add warning when using cloud sdk credentials

### 0.6.1 / 2017-10-18

* Fix file permissions

### 0.6.0 / 2017-10-17

* Support ruby-jwt 2.0
* Add simple credentials class

### 0.5.3 / 2017-07-21

* Fix file permissions on the gem's `.rb` files.

### 0.5.2 / 2017-07-19

* Add retry mechanism when fetching access tokens in `GCECredentials` and `UserRefreshCredentials` classes.
* Update Google API OAuth2 token credential URI to v4.

### 0.5.1 / 2016-01-06

* Change header name emitted by `Client#apply` from "Authorization" to "authorization" ([@murgatroid99][])
* Fix ADC not working on some windows machines ([@vsubramani][])

### 0.5.0 / 2015-10-12

* Initial support for user credentials ([@sqrrrl][])
* Update Signet to 0.7

### 0.4.2 / 2015-08-05

* Updated UserRefreshCredentials hash to use string keys ([@haabaato][])
* Add support for a system default credentials file. ([@mr-salty][])
* Fix bug when loading credentials from ENV ([@dwilkie][])
* Relax the constraint of dependent version of multi_json ([@igrep][])
* Enables passing credentials via environment variables. ([@haabaato][])

### 0.4.1 / 2015-04-25

* Improves handling of --no-scopes GCE authorization ([@tbetbetbe][])
* Refactoring and cleanup ([@joneslee85][])

### 0.4.0 / 2015-03-25

* Adds an implementation of JWT header auth ([@tbetbetbe][])

### 0.3.0 / 2015-03-23

* makes the scope parameter's optional in all APIs. ([@tbetbetbe][])
* changes the scope parameter's position in various constructors. ([@tbetbetbe][])

[@dwilkie]: https://github.com/dwilkie
[@haabaato]: https://github.com/haabaato
[@igrep]: https://github.com/igrep
[@joneslee85]: https://github.com/joneslee85
[@mr-salty]: https://github.com/mr-salty
[@tbetbetbe]: https://github.com/tbetbetbe
[@murgatroid99]: https://github.com/murgatroid99
[@vsubramani]: https://github.com/vsubramani
[@ball-hayden]: https://github.com/ball-hayden
