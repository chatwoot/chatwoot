# Release History

### 0.15.1 (2024-07-29)

#### Bug Fixes

* remove rexml from dependencies ([#19971](https://github.com/googleapis/google-api-ruby-client/issues/19971)) 

### 0.15.0 (2024-05-13)

#### Features

* Introduce api_version to discovery clients ([#18969](https://github.com/googleapis/google-api-ruby-client/issues/18969)) 

### 0.14.1 (2024-03-13)

#### Bug Fixes

* fixes uninitialized Pathname issue ([#18480](https://github.com/googleapis/google-api-ruby-client/issues/18480)) 

### 0.14.0 (2024-02-23)

#### Features

* Update minimum Ruby version to 2.7 ([#17896](https://github.com/googleapis/google-api-ruby-client/issues/17896)) 
#### Bug Fixes

* allow BaseService#root_url to be an Addressable::URI ([#17895](https://github.com/googleapis/google-api-ruby-client/issues/17895)) 

### 0.13.0 (2024-01-26)

#### Features

* Verify credential universe domain against configured universe domain ([#17569](https://github.com/googleapis/google-api-ruby-client/issues/17569)) 

### 0.12.0 (2024-01-22)

#### Features

* Support for universe_domain ([#17131](https://github.com/googleapis/google-api-ruby-client/issues/17131)) 

### 0.11.3 (2024-01-17)

#### Bug Fixes

* download with destination as pathname ([#17120](https://github.com/googleapis/google-api-ruby-client/issues/17120)) 

### 0.11.2 (2023-10-27)

#### Bug Fixes

* update ssl_config to point to system default root CA path ([#16446](https://github.com/googleapis/google-api-ruby-client/issues/16446)) 

### 0.11.1 (2023-07-20)

#### Documentation

* Document send_timeout_sec and fix up some types ([#14907](https://github.com/googleapis/google-api-ruby-client/issues/14907)) 

### 0.11.0 (2023-02-08)

#### Features

* Optimize memory usage when upload chunk size is set to 0 

### 0.10.0 (2023-01-26)

#### Features

* Allow chunk size zero for storage resumable upload ([#13283](https://github.com/googleapis/google-api-ruby-client/issues/13283)) 
* Make chunk size configurable ([#13216](https://github.com/googleapis/google-api-ruby-client/issues/13216)) 

### 0.9.5 (2023-01-12)

#### Bug Fixes

* Improve upload performance for Cloud Storage ([#13213](https://github.com/googleapis/google-api-ruby-client/issues/13213)) 

### 0.9.4 (2023-01-07)

#### Bug Fixes

* Recursively redact unsafe payloads from logs ([#13189](https://github.com/googleapis/google-api-ruby-client/issues/13189)) 

### 0.9.3 (2023-01-04)

#### Bug Fixes

* Removed some dead code ([#13099](https://github.com/googleapis/google-api-ruby-client/issues/13099)) 
* Replace `File.exists?` with `File.exist?` for compatibility with Ruby 3.2 ([#13161](https://github.com/googleapis/google-api-ruby-client/issues/13161)) 

### 0.9.2 (2022-12-13)

#### Bug Fixes

* Update UNSAFE_CLASS_NAMES ([#13030](https://github.com/googleapis/google-api-ruby-client/issues/13030)) 

### 0.9.1 (2022-10-18)

#### Bug Fixes

* Storage upload to handle empty string/file cases ([#12306](https://github.com/googleapis/google-api-ruby-client/issues/12306)) 

### 0.9.0 (2022-09-18)

#### Features

* add support to have invocation-id header ([#11655](https://github.com/googleapis/google-api-ruby-client/issues/11655)) 

### 0.8.0 (2022-09-16)

#### Features

* Add storage upload to move away from unified upload protocol ([#11508](https://github.com/googleapis/google-api-ruby-client/issues/11508)) 

### 0.7.2 (2022-09-15)

#### Bug Fixes

* do not reset query_values in case of form encoding ([#11654](https://github.com/googleapis/google-api-ruby-client/issues/11654)) 

### 0.7.1 (2022-09-14)

#### Bug Fixes

* Revert "chore(core): log errors as error instead of debug([#6494](https://github.com/googleapis/google-api-ruby-client/issues/6494))" ([#11561](https://github.com/googleapis/google-api-ruby-client/issues/11561)) 

### 0.7.0 (2022-06-30)

#### Features

* Add storage specific download to respond with http header 

### 0.6.0 (2022-06-15)

#### Features

* add few more errors as retriable errors

### 0.5.0 (2022-05-15)

#### Features

* Add support for retry options to be configurable

### 0.4.2 (2022-01-21)

#### Bug Fixes

* Support for max elapsed time configuration.

### 0.4.1 (2021-07-19)

* FIX: Prevent duplicated pagination when a response returns an empty string as the next page token.

### 0.4.0 (2021-06-28)

* Expanded googleauth dependency to include future 1.x versions

### 0.3.0 (2021-03-07)

#### Features

* Drop support for Ruby 2.4 and add support for Ruby 3.0

### 0.2.1 (2021-01-25)

#### Bug Fixes

* Add webrick to the gem dependencies, for Ruby 3 compatibility

### 0.2.0 (2021-01-06)

* Munge reported client version so backends can recognize split clients

### 0.1.0 (2021-01-01)

* Initial release, extracted from google-api-client.
