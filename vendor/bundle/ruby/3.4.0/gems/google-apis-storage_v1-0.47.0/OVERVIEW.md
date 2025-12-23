# Simple REST client for version V1 of the Cloud Storage JSON API

This is a simple client library for version V1 of the Cloud Storage JSON API. It provides:

* A client object that connects to the HTTP/JSON REST endpoint for the service.
* Ruby objects for data structures related to the service.
* Integration with the googleauth gem for authentication using OAuth, API keys, and service accounts.
* Control of retry, pagination, and timeouts.

Note that although this client library is supported and will continue to be updated to track changes to the service, it is otherwise considered complete and not under active development. Many Google services, especially Google Cloud Platform services, may provide a more modern client that is under more active development and improvement. See the section below titled *Which client should I use?* for more information.

## Getting started

### Before you begin

There are a few setup steps you need to complete before you can use this library:

 1. If you don't already have a Google account, [sign up](https://www.google.com/accounts).
 2. If you have never created a Google APIs Console project, read about [Managing Projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects) and create a project in the [Google API Console](https://console.cloud.google.com/).
 3. Most APIs need to be enabled for your project. [Enable it](https://console.cloud.google.com/apis/library/storage.googleapis.com) in the console.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'google-apis-storage_v1', '~> 0.1'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install google-apis-storage_v1
```

### Creating a client object

Once the gem is installed, you can load the client code and instantiate a client.

```ruby
# Load the client
require "google/apis/storage_v1"

# Create a client object
client = Google::Apis::StorageV1::StorageService.new

# Authenticate calls
client.authorization = # ... use the googleauth gem to create credentials
```

See the class reference docs for information on the methods you can call from a client.

## Documentation

More detailed descriptions of the Google simple REST clients are available in two documents.

 *  The [Usage Guide](https://github.com/googleapis/google-api-ruby-client/blob/main/docs/usage-guide.md) discusses how to make API calls, how to use the provided data structures, and how to work the various features of the client library, including media upload and download, error handling, retries, pagination, and logging.
 *  The [Auth Guide](https://github.com/googleapis/google-api-ruby-client/blob/main/docs/auth-guide.md) discusses authentication in the client libraries, including API keys, OAuth 2.0, service accounts, and environment variables.

(Note: the above documents are written for the simple REST clients in general, and their examples may not reflect the Storage service in particular.)

For reference information on specific calls in the Cloud Storage JSON API, see the {Google::Apis::StorageV1::StorageService class reference docs}.

## Which client should I use?

Google provides two types of Ruby API client libraries: **simple REST clients** and **modern clients**.

This library, `google-apis-storage_v1`, is a simple REST client. You can identify these clients by their gem names, which are always in the form `google-apis-<servicename>_<serviceversion>`. The simple REST clients connect to HTTP/JSON REST endpoints and are automatically generated from service discovery documents. They support most API functionality, but their class interfaces are sometimes awkward.

Modern clients are produced by a modern code generator, sometimes combined with hand-crafted functionality. Most modern clients connect to high-performance gRPC endpoints, although a few are backed by REST services. Modern clients are available for many Google services, especially Google Cloud Platform services, but do not yet support all the services covered by the simple clients.

Gem names for modern clients are often of the form `google-cloud-<service_name>`. (For example, [google-cloud-pubsub](https://rubygems.org/gems/google-cloud-pubsub).) Note that most modern clients also have corresponding "versioned" gems with names like `google-cloud-<service_name>-<version>`. (For example, [google-cloud-pubsub-v1](https://rubygems.org/gems/google-cloud-pubsub-v1).) The "versioned" gems can be used directly, but often provide lower-level interfaces. In most cases, the main gem is recommended.

**For most users, we recommend the modern client, if one is available.** Compared with simple clients, modern clients are generally much easier to use and more Ruby-like, support more advanced features such as streaming and long-running operations, and often provide much better performance. You may consider using a simple client instead, if a modern client is not yet available for the service you want to use, or if you are not able to use gRPC on your infrastructure.

The [product documentation](https://developers.google.com/storage/docs/json_api/) may provide guidance regarding the preferred client library to use.

## Supported Ruby versions

This library is supported on Ruby 2.7+.

Google provides official support for Ruby versions that are actively supported by Ruby Core -- that is, Ruby versions that are either in normal maintenance or in security maintenance, and not end of life. Older versions of Ruby _may_ still work, but are unsupported and not recommended. See https://www.ruby-lang.org/en/downloads/branches/ for details about the Ruby support schedule.

## License

This library is licensed under Apache 2.0. Full license text is available in the {file:LICENSE.md LICENSE}.

## Support

Please [report bugs at the project on Github](https://github.com/google/google-api-ruby-client/issues). Don't hesitate to [ask questions](http://stackoverflow.com/questions/tagged/google-api-ruby-client) about the client or APIs on [StackOverflow](http://stackoverflow.com).
