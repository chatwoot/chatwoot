[![Integration](https://github.com/opensearch-project/opensearch-ruby/actions/workflows/main.yml/badge.svg)](https://github.com/opensearch-project/opensearch-ruby/actions/workflows/main.yml)
[![Chat](https://img.shields.io/badge/chat-on%20forums-blue)](https://discuss.opendistrocommunity.dev/c/clients/)
![PRs welcome!](https://img.shields.io/badge/PRs-welcome!-success)

![OpenSearch logo](https://raw.githubusercontent.com/opensearch-project/opensearch-ruby/main/OpenSearch.svg)

OpenSearch Ruby Client

- [Welcome!](#welcome)
- [Sample Code](#sample-code)
- [Project Resources](#project-resources)
- [Transport Features](#transport-features)
- [Code of Conduct](#code-of-conduct)
- [User Guide](#user-guide)
- [Compatibility with OpenSearch](#compatibility-with-opensearch)
- [Developer Guide](#developer-guide)
- [Security](#security)
- [License](#license)
- [Copyright](#copyright)

## Welcome!

**opensearch-ruby** is [a community-driven, open source fork](https://aws.amazon.com/blogs/opensource/introducing-opensearch/) of elasticsearch-ruby licensed under the [Apache v2.0 License](LICENSE.txt).
For more information, see [opensearch.org](https://opensearch.org/).

## Sample Code

Please see the [USER_GUIDE](USER_GUIDE.md) for code snippets.

## Project Resources

* [Project Website](https://opensearch.org/)
* [Documentation](https://opensearch.org/docs/latest/clients/ruby/)
* [Ruby Gems](https://rubygems.org/gems/opensearch-ruby).
* Need help? Try [Forums](https://discuss.opendistrocommunity.dev/c/clients/)
* [Project Principles](https://opensearch.org/#principles)
* [Contributing to OpenSearch](CONTRIBUTING.md)
* [Maintainer Responsibilities](MAINTAINERS.md)
* [Release Management](RELEASING.md)
* [Admin Responsibilities](ADMINS.md)
* [Security](SECURITY.md)

## Transport Features

The Transport layer of the client, `OpenSearch::Transport`, provides the following features:

* Pluggable logging and tracing
* Pluggable connection selection strategies (round-robin, random, custom)
* Pluggable transport implementation, customizable and extendable
* Pluggable serializer implementation
* Request retries and dead connections handling
* Node reloading (based on cluster state) on errors or on demand

For optimal performance, use a HTTP library which supports persistent ("keep-alive") connections, such as [Patron](https://github.com/toland/patron) or [Typhoeus](https://github.com/typhoeus/typhoeus).
Most such HTTP libraries are used through the [Faraday](https://rubygems.org/gems/faraday) HTTP library and its [adapters](https://github.com/lostisland/awesome-faraday/#adapters).

Include the library's gem and adapter gem, and require the library and adapter in your code, and it will be automatically used.
If you don't use Bundler, you may need to require the library explicitly (like `require 'faraday/patron'`).

Currently these libraries will be automatically detected and used:
- [Patron](https://github.com/toland/patron) through [faraday-patron](https://github.com/lostisland/faraday-patron)
- [Typhoeus](https://github.com/typhoeus/typhoeus) through [faraday-typhoeus](https://github.com/dleavitt/faraday-typhoeus) for Faraday 2 or higher, or Faraday's built-in adapter for Faraday 1.
- [HTTPClient](https://rubygems.org/gems/httpclient) through [faraday-httpclient](https://github.com/lostisland/faraday-httpclient)
- [Net::HTTP::Persistent](https://rubygems.org/gems/net-http-persistent) through [faraday-net_http_persistent](https://github.com/lostisland/faraday-net_http_persistent)

**Note on [Typhoeus](https://github.com/typhoeus/typhoeus)**: You need to use v1.4.0 or up since older versions are not compatible with Faraday 1.0 or higher.

**Note on [Faraday](https://rubygems.org/gems/faraday)**: If you use Faraday 2.0 or higher, if the adapter is in a separate gem, you will likely need to declare that gem as well. Only the Net::HTTP adapter gem is included by default. Faraday 1.x includes most common adapter gems already.

## DSL Features

The `opensearch-dsl` library provides a Ruby API for the `OpenSearch Query DSL`.

The library allows to programatically build complex search definitions for OpenSearch in Ruby, which are translated to Hashes, and ultimately, JSON, the language of OpenSearch.

All OpenSearch DSL features are supported, namely:

* Queries and Filter context
* Aggregations
* Suggestions
* Sorting
* Pagination
* Options

## Code of Conduct

This project has adopted the [Amazon Open Source Code of Conduct](CODE_OF_CONDUCT.md). For more information see the [Code of Conduct FAQ](https://aws.github.io/code-of-conduct-faq), or contact [opensource-codeofconduct@amazon.com](mailto:opensource-codeofconduct@amazon.com) with any additional questions or comments.

## User Guide

See [USER_GUIDE](USER_GUIDE.md).

## Compatibility with OpenSearch

See [Compatibility](COMPATIBILITY.md).

## Upgrading

See [UPGRADING](UPGRADING.md).

## Developer Guide

See [DEVELOPER_GUIDE](DEVELOPER_GUIDE.md).

## Security

If you discover a potential security issue in this project we ask that you notify AWS/Amazon Security via our [vulnerability reporting page](http://aws.amazon.com/security/vulnerability-reporting/) or directly via email to aws-security@amazon.com. Please do **not** create a public GitHub issue.

## License

This project is licensed under the [Apache v2.0 License](LICENSE.txt).

## Copyright

Copyright OpenSearch Contributors. See [NOTICE](NOTICE.txt) for details.
