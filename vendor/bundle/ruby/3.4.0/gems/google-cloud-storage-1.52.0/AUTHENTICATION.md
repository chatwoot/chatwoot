# Authentication

In general, the google-cloud-storage library uses [Service
Account](https://cloud.google.com/iam/docs/creating-managing-service-accounts)
credentials to connect to Google Cloud services. When running on Google Cloud
Platform (GCP), including Google Compute Engine (GCE), Google Kubernetes Engine
(GKE), Google App Engine (GAE), Google Cloud Functions (GCF) and Cloud Run,
the credentials will be discovered automatically. When running on other
environments, the Service Account credentials can be specified by providing the
path to the [JSON
keyfile](https://cloud.google.com/iam/docs/managing-service-account-keys) for
the account (or the JSON itself) in environment variables. Additionally, Cloud
SDK credentials can also be discovered automatically, but this is only
recommended during development.

## Project and Credential Lookup

The google-cloud-storage library aims to make authentication as simple as
possible, and provides several mechanisms to configure your system without
providing **Project ID** and **Service Account Credentials** directly in code.

**Project ID** is discovered in the following order:

1. Specify project ID in method arguments
2. Specify project ID in configuration
3. Discover project ID in environment variables
4. Discover GCE project ID

**Credentials** are discovered in the following order:

1. Specify credentials in method arguments
2. Specify credentials in configuration
3. Discover credentials path in environment variables
4. Discover credentials JSON in environment variables
5. Discover credentials file in the Cloud SDK's path
6. Discover GCE credentials

### Google Cloud Platform environments

When running on Google Cloud Platform (GCP), including Google Compute Engine (GCE),
Google Kubernetes Engine (GKE), Google App Engine (GAE), Google Cloud Functions
(GCF) and Cloud Run, the **Project ID** and **Credentials** and are discovered
automatically. Code should be written as if already authenticated.

### Environment Variables

The **Project ID** and **Credentials JSON** can be placed in environment
variables instead of declaring them directly in code. Each service has its own
environment variable, allowing for different service accounts to be used for
different services. (See the READMEs for the individual service gems for
details.) The path to the **Credentials JSON** file can be stored in the
environment variable, or the **Credentials JSON** itself can be stored for
environments such as Docker containers where writing files is difficult or not
encouraged.

The environment variables that Storage checks for project ID are:

1. `STORAGE_PROJECT`
2. `GOOGLE_CLOUD_PROJECT`

The environment variables that Storage checks for credentials are configured on {Google::Cloud::Storage::Credentials}:

1. `STORAGE_CREDENTIALS` - Path to JSON file, or JSON contents
2. `STORAGE_KEYFILE` - Path to JSON file, or JSON contents
3. `GOOGLE_CLOUD_CREDENTIALS` - Path to JSON file, or JSON contents
4. `GOOGLE_CLOUD_KEYFILE` - Path to JSON file, or JSON contents
5. `GOOGLE_APPLICATION_CREDENTIALS` - Path to JSON file

```ruby
require "google/cloud/storage"

ENV["STORAGE_PROJECT"]     = "my-project-id"
ENV["STORAGE_CREDENTIALS"] = "path/to/keyfile.json"

storage = Google::Cloud::Storage.new
```

### Configuration

The **Project ID** and the path to the **Credentials JSON** file can be configured
instead of placing them in environment variables or providing them as arguments.

```ruby
require "google/cloud/storage"

Google::Cloud::Storage.configure do |config|
  config.project_id  = "my-project-id"
  config.credentials = "path/to/keyfile.json"
end

storage = Google::Cloud::Storage.new
```

### Cloud SDK

This option allows for an easy way to authenticate during development. If
credentials are not provided in code or in environment variables, then Cloud SDK
credentials are discovered.

To configure your system for this, simply:

1. [Download and install the Cloud SDK](https://cloud.google.com/sdk)
2. Authenticate using OAuth 2.0 `$ gcloud auth login`
3. Write code as if already authenticated.

**NOTE:** The use of Cloud SDK credentials is _not_ recommended for running in
production. The Cloud SDK *should* only be used during development.

**NOTE:** The use of Cloud SDK credentials may not support certain methods such as
those that produce
[signed URLs](https://cloud.google.com/storage/docs/access-control/signed-urls) and
post objects. For these methods, authentication using a service account JSON key file
is required.

## Creating a Service Account

Google Cloud requires a **Project ID** and **Service Account Credentials** to
connect to the APIs. You will use the **Project ID** and **JSON key file** to
connect to most services with google-cloud-storage.

If you are not running this client on Google Compute Engine, you need a Google
Developers service account.

1. Visit the [Google Cloud Console](https://console.cloud.google.com/project).
1. Create a new project or click on an existing project.
1. Activate the menu in the upper left and select **APIs & Services**. From
   here, you will enable the APIs that your application requires.

   *Note: You may need to enable billing in order to use these services.*

1. Select **Credentials** from the side navigation.

   Find the "Create credentials" drop down near the top of the page, and select
   "Service account" to be guided through downloading a new JSON key file.

   If you want to re-use an existing service account, you can easily generate 
   a new key file. Just select the account you wish to re-use click the pencil
   tool on the right side to edit the service account, select the **Keys** tab,
   and then select **Add Key**.

   The key file you download will be used by this library to authenticate API
   requests and should be stored in a secure location.

## Troubleshooting

If you're having trouble authenticating you can ask for help by following the
{file:TROUBLESHOOTING.md Troubleshooting Guide}.
