## With `google-cloud-ruby`

With `google-cloud-ruby` it's incredibly easy to get authenticated and start using Google's APIs. You can set your credentials on a global basis as well as on a per-API basis.

### Google Cloud Platform environments

While running on Google Cloud Platform (GCP), including Google Compute Engine (GCE), Google Kubernetes Engine (GKE), Google App Engine (GAE), Google Cloud Functions (GCF) and Cloud Run, no extra work is needed. The **Project ID** and **Credentials** and are discovered automatically. Code should be written as if already authenticated.

### Project and Credential Lookup

The google-cloud library aims to make authentication as simple as possible, and provides several mechanisms to configure your system without providing **Project ID** and **Service Account Credentials** directly in code.

**Project ID** is discovered in the following order:

1. Specify project ID in code
2. Discover project ID in environment variables
3. Discover GCE project ID

**Credentials** are discovered in the following order:

1. Specify credentials in code
2. Discover credentials path in environment variables
3. Discover credentials JSON in environment variables
4. Discover credentials file in the Cloud SDK's path
5. Discover GCE credentials

### Environment Variables

The **Project ID** and **Credentials JSON** can be placed in environment variables instead of declaring them directly in code. Each service has its own environment variable, allowing for different service accounts to be used for different services. The path to the **Credentials JSON** file can be stored in the environment variable, or the **Credentials JSON** itself can be stored for environments such as Docker containers where writing files is difficult or not encouraged.

Here are the environment variables (in the order they are checked) for project ID:

1. `GOOGLE_CLOUD_PROJECT`

Here are the environment variables (in the order they are checked) for credentials:

1. `GOOGLE_CLOUD_KEYFILE` - Path to JSON file
2. `GOOGLE_CLOUD_KEYFILE_JSON` - JSON contents



