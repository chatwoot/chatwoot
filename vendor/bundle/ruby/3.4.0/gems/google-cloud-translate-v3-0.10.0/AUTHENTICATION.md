# Authentication

In general, the google-cloud-translate-v3 library uses
[Service Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
credentials to connect to Google Cloud services. When running within
[Google Cloud Platform environments](#google-cloud-platform-environments) the
credentials will be discovered automatically. When running on other
environments, the Service Account credentials can be specified by providing the
path to the
[JSON keyfile](https://cloud.google.com/iam/docs/managing-service-account-keys)
for the account (or the JSON itself) in
[environment variables](#environment-variables). Additionally, Cloud SDK
credentials can also be discovered automatically, but this is only recommended
during development.

## Quickstart

1. [Create a service account and credentials](#creating-a-service-account).
2. Set the [environment variable](#environment-variables).

```sh
export TRANSLATE_CREDENTIALS=path/to/keyfile.json
```

3. Initialize the client.

```ruby
require "google/cloud/translate/v3"

client = ::Google::Cloud::Translate::V3::TranslationService::Client.new
```

## Credential Lookup

The google-cloud-translate-v3 library aims to make authentication
as simple as possible, and provides several mechanisms to configure your system
without requiring **Service Account Credentials** directly in code.

**Credentials** are discovered in the following order:

1. Specify credentials in method arguments
2. Specify credentials in configuration
3. Discover credentials path in environment variables
4. Discover credentials JSON in environment variables
5. Discover credentials file in the Cloud SDK's path
6. Discover GCP credentials

### Google Cloud Platform environments

When running on Google Cloud Platform (GCP), including Google Compute Engine
(GCE), Google Kubernetes Engine (GKE), Google App Engine (GAE), Google Cloud
Functions (GCF) and Cloud Run, **Credentials** are discovered automatically.
Code should be written as if already authenticated.

### Environment Variables

The **Credentials JSON** can be placed in environment variables instead of
declaring them directly in code. Each service has its own environment variable,
allowing for different service accounts to be used for different services. (See
the READMEs for the individual service gems for details.) The path to the
**Credentials JSON** file can be stored in the environment variable, or the
**Credentials JSON** itself can be stored for environments such as Docker
containers where writing files is difficult or not encouraged.

The environment variables that google-cloud-translate-v3
checks for credentials are configured on the service Credentials class (such as
{::Google::Cloud::Translate::V3::TranslationService::Credentials}):

* `TRANSLATE_CREDENTIALS` - Path to JSON file, or JSON contents
* `TRANSLATE_KEYFILE` - Path to JSON file, or JSON contents
* `GOOGLE_CLOUD_CREDENTIALS` - Path to JSON file, or JSON contents
* `GOOGLE_CLOUD_KEYFILE` - Path to JSON file, or JSON contents
* `GOOGLE_APPLICATION_CREDENTIALS` - Path to JSON file

```ruby
require "google/cloud/translate/v3"

ENV["TRANSLATE_CREDENTIALS"] = "path/to/keyfile.json"

client = ::Google::Cloud::Translate::V3::TranslationService::Client.new
```

### Configuration

The path to the **Credentials JSON** file can be configured instead of storing
it in an environment variable. Either on an individual client initialization:

```ruby
require "google/cloud/translate/v3"

client = ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
  config.credentials = "path/to/keyfile.json"
end
```

Or globally for all clients:

```ruby
require "google/cloud/translate/v3"

::Google::Cloud::Translate::V3::TranslationService::Client.configure do |config|
  config.credentials = "path/to/keyfile.json"
end

client = ::Google::Cloud::Translate::V3::TranslationService::Client.new
```

### Cloud SDK

This option allows for an easy way to authenticate during development. If
credentials are not provided in code or in environment variables, then Cloud SDK
credentials are discovered.

To configure your system for this, simply:

1. [Download and install the Cloud SDK](https://cloud.google.com/sdk)
2. Authenticate using OAuth 2.0 `$ gcloud auth application-default login`
3. Write code as if already authenticated.

**NOTE:** This is _not_ recommended for running in production. The Cloud SDK
*should* only be used during development.

## Creating a Service Account

Google Cloud requires **Service Account Credentials** to
connect to the APIs. You will use the **JSON key file** to
connect to most services with google-cloud-translate-v3.

If you are not running this client within
[Google Cloud Platform environments](#google-cloud-platform-environments), you
need a Google Developers service account.

1. Visit the [Google Cloud Console](https://console.cloud.google.com/project).
2. Create a new project or click on an existing project.
3. Activate the menu in the upper left and select **APIs & Services**. From
   here, you will enable the APIs that your application requires.

   *Note: You may need to enable billing in order to use these services.*

4. Select **Credentials** from the side navigation.

   Find the "Create credentials" drop down near the top of the page, and select
   "Service account" to be guided through downloading a new JSON key file.

   If you want to re-use an existing service account, you can easily generate a
   new key file. Just select the account you wish to re-use, click the pencil
   tool on the right side to edit the service account, select the **Keys** tab,
   and then select **Add Key**.

   The key file you download will be used by this library to authenticate API
   requests and should be stored in a secure location.
