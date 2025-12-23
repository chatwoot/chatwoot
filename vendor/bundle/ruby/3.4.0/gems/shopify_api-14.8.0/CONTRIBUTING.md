
Submitting Issues
-----------------
Submitting Issues

Please open an issue here if you encounter a specific bug with this API client library or if something is documented here https://shopify.dev/docs/apps but is missing from this package.

General questions about the Shopify API and usage of this package (not necessarily a bug) should be posted on the [Shopify forums](https://community.shopify.com/c/partners-and-developers/ct-p/appdev).

When in doubt, post on the forum first. You'll likely have your questions answered more quickly if you post there; more people monitor the forum than Github.

In order for us to best triage the issue, please include steps to reproduce the issue as well as the impacted feature.

## Roadmap

The focus of development efforts by maintainers of this project a roadmap will be proposed via PR and accessible at any point in the ROADMAP.md file.

Working with a pull request modify the [ROADMAP.md](https://github.com/Shopify/shopify-api-ruby/blob/aa0b7f9a5a9095ca11f3f93f9aecc72e8daa6bce/ROADMAP.md) allows us to invite community feedback on the direction while not adding another communication avenue. While there are certainly better tools for the job than a markdown file for this, we are aiming to keep a minimal toolset to help us better manage the communication channels that we have open.

If there are concerns with the direction and priorities of the maintainers, this roadmap PR is the appropriate place to share your concerns.

## Submitting Pull Requests

We welcome pull requests and help from the community! PRs fixing bugs will take priority to triaging proposed net new functionality. If you do want to add a feature, we recommend opening an issue first exploring the appetite of the community / maintainers to ensure there is alignment on direction before you spend time on the PR.

## Gem Architecture
Understanding how all the components of the Shopify App development stack work together will help best understand what level of abstraction a feature is meant to be applied. Please consider this architecture before introducing new functionally to ensure it is in the right place:

| Gem Name | Job |
|---|---|
| Shopify API (this gem) | Obtain a session, clients for APIs (REST, GraphQL), error handling, webhook management |
| REST Resources | Interfaces to the APIs. Response casting into defined objects with attributes/methods |
| Shopify App | Build Shopify app using Rails conventions. Oauth, webhook processing, persistence, etc |
| App Template | Template demonstrating how to use all these components in one starting boilerplate application |
