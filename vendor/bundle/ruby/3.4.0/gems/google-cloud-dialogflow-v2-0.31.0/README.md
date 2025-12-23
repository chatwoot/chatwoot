# Ruby Client for the Dialogflow V2 API

Builds conversational interfaces (for example, chatbots, and voice-powered apps and devices).

Dialogflow is an end-to-end, build-once deploy-everywhere development suite for creating conversational interfaces for websites, mobile applications, popular messaging platforms, and IoT devices. You can use it to build interfaces (such as chatbots and conversational IVR) that enable natural and rich interactions between your users and your business. This client is for Dialogflow ES, providing the standard agent type suitable for small and simple agents.

https://github.com/googleapis/google-cloud-ruby

This gem is a _versioned_ client. It provides basic client classes for a
specific version of the Dialogflow V2 API. Most users should consider using
the main client gem,
[google-cloud-dialogflow](https://rubygems.org/gems/google-cloud-dialogflow).
See the section below titled *Which client should I use?* for more information.

## Installation

```
$ gem install google-cloud-dialogflow-v2
```

## Before You Begin

In order to use this library, you first need to go through the following steps:

1. [Select or create a Cloud Platform project.](https://console.cloud.google.com/project)
1. [Enable billing for your project.](https://cloud.google.com/billing/docs/how-to/modify-project#enable_billing_for_a_project)
1. [Enable the API.](https://console.cloud.google.com/apis/library/dialogflow.googleapis.com)
1. {file:AUTHENTICATION.md Set up authentication.}

## Quick Start

```ruby
require "google/cloud/dialogflow/v2"

client = ::Google::Cloud::Dialogflow::V2::Agents::Client.new
request = ::Google::Cloud::Dialogflow::V2::GetAgentRequest.new # (request fields as keyword arguments...)
response = client.get_agent request
```

View the [Client Library Documentation](https://cloud.google.com/ruby/docs/reference/google-cloud-dialogflow-v2/latest)
for class and method documentation.

See also the [Product Documentation](https://cloud.google.com/dialogflow)
for general usage information.

## Enabling Logging

To enable logging for this library, set the logger for the underlying [gRPC](https://github.com/grpc/grpc/tree/master/src/ruby) library.
The logger that you set may be a Ruby stdlib [`Logger`](https://ruby-doc.org/current/stdlibs/logger/Logger.html) as shown below,
or a [`Google::Cloud::Logging::Logger`](https://cloud.google.com/ruby/docs/reference/google-cloud-logging/latest)
that will write logs to [Cloud Logging](https://cloud.google.com/logging/). See [grpc/logconfig.rb](https://github.com/grpc/grpc/blob/master/src/ruby/lib/grpc/logconfig.rb)
and the gRPC [spec_helper.rb](https://github.com/grpc/grpc/blob/master/src/ruby/spec/spec_helper.rb) for additional information.

Configuring a Ruby stdlib logger:

```ruby
require "logger"

module MyLogger
  LOGGER = Logger.new $stderr, level: Logger::WARN
  def logger
    LOGGER
  end
end

# Define a gRPC module-level logger method before grpc/logconfig.rb loads.
module GRPC
  extend MyLogger
end
```


## Google Cloud Samples

To browse ready to use code samples check [Google Cloud Samples](https://cloud.google.com/docs/samples).

## Supported Ruby Versions

This library is supported on Ruby 2.6+.

Google provides official support for Ruby versions that are actively supported
by Ruby Core—that is, Ruby versions that are either in normal maintenance or
in security maintenance, and not end of life. Older versions of Ruby _may_
still work, but are unsupported and not recommended. See
https://www.ruby-lang.org/en/downloads/branches/ for details about the Ruby
support schedule.

## Which client should I use?

Most modern Ruby client libraries for Google APIs come in two flavors: the main
client library with a name such as `google-cloud-dialogflow`,
and lower-level _versioned_ client libraries with names such as
`google-cloud-dialogflow-v2`.
_In most cases, you should install the main client._

### What's the difference between the main client and a versioned client?

A _versioned client_ provides a basic set of data types and client classes for
a _single version_ of a specific service. (That is, for a service with multiple
versions, there might be a separate versioned client for each service version.)
Most versioned clients are written and maintained by a code generator.

The _main client_ is designed to provide you with the _recommended_ client
interfaces for the service. There will be only one main client for any given
service, even a service with multiple versions. The main client includes
factory methods for constructing the client objects we recommend for most
users. In some cases, those will be classes provided by an underlying versioned
client; in other cases, they will be handwritten higher-level client objects
with additional capabilities, convenience methods, or best practices built in.
Generally, the main client will default to a recommended service version,
although in some cases you can override this if you need to talk to a specific
service version.

### Why would I want to use the main client?

We recommend that most users install the main client gem for a service. You can
identify this gem as the one _without_ a version in its name, e.g.
`google-cloud-dialogflow`.
The main client is recommended because it will embody the best practices for
accessing the service, and may also provide more convenient interfaces or
tighter integration into frameworks and third-party libraries. In addition, the
documentation and samples published by Google will generally demonstrate use of
the main client.

### Why would I want to use a versioned client?

You can use a versioned client if you are content with a possibly lower-level
class interface, you explicitly want to avoid features provided by the main
client, or you want to access a specific service version not be covered by the
main client. You can identify versioned client gems because the service version
is part of the name, e.g. `google-cloud-dialogflow-v2`.

### What about the google-apis-<name> clients?

Client library gems with names that begin with `google-apis-` are based on an
older code generation technology. They talk to a REST/JSON backend (whereas
most modern clients talk to a [gRPC](https://grpc.io/) backend) and they may
not offer the same performance, features, and ease of use provided by more
modern clients.

The `google-apis-` clients have wide coverage across Google services, so you
might need to use one if there is no modern client available for the service.
However, if a modern client is available, we generally recommend it over the
older `google-apis-` clients.
