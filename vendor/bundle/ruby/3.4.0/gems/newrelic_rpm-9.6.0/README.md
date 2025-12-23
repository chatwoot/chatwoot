<a href="https://opensource.newrelic.com/oss-category/#community-plus"><picture><source media="(prefers-color-scheme: dark)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/dark/Community_Plus.png"><source media="(prefers-color-scheme: light)" srcset="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"><img alt="New Relic Open Source community plus project banner." src="https://github.com/newrelic/opensource-website/raw/main/src/images/categories/Community_Plus.png"></picture></a>

# New Relic Ruby Agent

The New Relic Ruby agent monitors your applications to help you
[identify and solve performance issues](https://docs.newrelic.com/docs/agents/ruby-agent/getting-started/introduction-new-relic-ruby#monitor-performance).
You can also extend the agent's performance monitoring to
[collect and analyze business data](https://docs.newrelic.com/docs/agents/ruby-agent/getting-started/introduction-new-relic-ruby#business-data)
to help you improve the customer experience and make data-driven business decisions.

The New Relic Ruby agent is dual-purposed as either a Gem or a Rails plugin,
hosted on [GitHub](https://github.com/newrelic/newrelic-ruby-agent).

This code is actively maintained by New Relic engineering teams and delivered here in GitHub. See below for troubleshooting and defect reporting instructions.

[![Gem Version](https://badge.fury.io/rb/newrelic_rpm.svg)](https://badge.fury.io/rb/newrelic_rpm)

## Supported Environments

An up-to-date list of Ruby versions and frameworks for the latest agent
can be found on [our docs site](http://docs.newrelic.com/docs/ruby/supported-frameworks).

You can also monitor non-web applications. Refer to the "Other
Environments" section below.

## Installing and Using

The latest released gem for the Ruby agent can be found at [RubyGems.org](https://rubygems.org/gems/newrelic_rpm)

### Quick Start

#### With Bundler

For using with Bundler, add the Ruby agent to your project's Gemfile.

```ruby
gem 'newrelic_rpm'
```

and run `bundle install` to activate the new gem.

#### Without Bundler

If you are not using Bundler, install the gem with:

```bash
gem install newrelic_rpm
```

and then require the New Relic Ruby agent in your Ruby start-up sequence:

```ruby
require 'newrelic_rpm'
```

#### Other Environments

Assuming you have installed the agent per above, you may also need to tell the Ruby agent to start for some frameworks and non-framework environments. To do so, add the following to your Ruby start-up sequence start the agent:

```ruby
NewRelic::Agent.manual_start
```

### Complete Install Instructions

For complete documentation on installing the New Relic Ruby agent, see the following links:

* [Introduction](https://docs.newrelic.com/docs/agents/ruby-agent/getting-started/introduction-new-relic-ruby)
* [Install the New Relic Ruby agent](https://docs.newrelic.com/docs/agents/ruby-agent/installation/install-new-relic-ruby-agent)
* [Configure the agent](https://docs.newrelic.com/docs/agents/ruby-agent/configuration/ruby-agent-configuration)
* [Update the agent](https://docs.newrelic.com/docs/agents/ruby-agent/installation/update-ruby-agent)
* [Rails plugin installation](https://docs.newrelic.com/docs/agents/ruby-agent/installation/ruby-agent-installation-rails-plugin)
* [GAE Flexible Environment](https://docs.newrelic.com/docs/agents/ruby-agent/installation/install-new-relic-ruby-agent-gae-flexible-environment)
* [Pure Rack Apps](http://docs.newrelic.com/docs/ruby/rack-middlewares)
* [Ruby agent and Heroku](https://docs.newrelic.com/docs/agents/ruby-agent/installation/ruby-agent-heroku)
* [Background Jobs](https://docs.newrelic.com/docs/agents/ruby-agent/background-jobs/monitor-ruby-background-processes)
* [Uninstall the Ruby agent](https://docs.newrelic.com/docs/agents/ruby-agent/installation/uninstall-ruby-agent)

### Recording Deploys

The Ruby agent supports recording deployments in New Relic via a command line
tool or Capistrano recipes. For more information on these features, see
[our deployment documentation](http://docs.newrelic.com/docs/ruby/recording-deployments-with-the-ruby-agent)
for more information.


## Support

Should you need assistance with New Relic products, you are in good hands with several support diagnostic tools and support channels.

This [troubleshooting framework](https://forum.newrelic.com/s/hubtopic/aAX8W0000008bSgWAI/ruby-troubleshooting-framework-install) steps you through common troubleshooting questions.

New Relic offers NRDiag, [a client-side diagnostic utility](https://docs.newrelic.com/docs/using-new-relic/cross-product-functions/troubleshooting/new-relic-diagnostics) that automatically detects common problems with New Relic agents. If NRDiag detects a problem, it suggests troubleshooting steps. NRDiag can also automatically attach troubleshooting data to a New Relic Support ticket.

If the issue has been confirmed as a bug or is a Feature request, please file a GitHub issue.

**Support Channels**

* [New Relic Documentation](https://docs.newrelic.com/docs/agents/ruby-agent): Comprehensive guidance for using our platform
* [New Relic Community](https://forum.newrelic.com): The best place to engage in troubleshooting questions
* [New Relic Developer](https://developer.newrelic.com/): Resources for building a custom observability applications
* [New Relic University](https://learn.newrelic.com/): A range of online training for New Relic users of every level
* [New Relic Technical Support](https://support.newrelic.com/) 24/7/365 ticketed support. Read more about our [Technical Support Offerings](https://docs.newrelic.com/docs/licenses/license-information/general-usage-licenses/support-plan).

## Privacy

At New Relic we take your privacy and the security of your information seriously, and are committed to protecting your information. We must emphasize the importance of not sharing personal data in public forums, and ask all users to scrub logs and diagnostic information for sensitive information, whether personal, proprietary, or otherwise.

We define “Personal Data” as any information relating to an identified or identifiable individual, including, for example, your name, phone number, post code or zip code, Device ID, IP address, and email address.

Please review [New Relic’s General Data Privacy Notice](https://newrelic.com/termsandconditions/privacy) for more information.

## Contributing

We encourage contributions to improve the New Relic Ruby agent! Keep in mind when you submit your pull request, you'll need to sign the Contributor License Agreement (CLA) via the click-through using CLA-Assistant. You only have to sign the CLA one time per project.
If you have any questions, or to execute our corporate CLA (required if your contribution is on behalf of a company), please drop us an email at opensource@newrelic.com.

**A note about vulnerabilities**

As noted in our [security policy](https://github.com/newrelic/newrelic-ruby-agent/security/policy), New Relic is committed to the privacy and security of our customers and their data. We believe that providing coordinated disclosure by security researchers and engaging with the security community are important means to achieve our security goals.

If you believe you have found a security vulnerability in this project or any of New Relic's products or websites, we welcome and greatly appreciate you reporting it to New Relic through [HackerOne](https://hackerone.com/newrelic).

If you would like to contribute to this project, please review [these guidelines](https://github.com/newrelic/newrelic-ruby-agent/blob/main/CONTRIBUTING.md).

To [all contributors](https://github.com/newrelic/newrelic-ruby-agent/graphs/contributors), we thank you!  Without your contribution, this project would not be what it is today.  We also host a community project page dedicated to
the [New Relic Ruby agent](https://opensource.newrelic.com/projects/newrelic/newrelic-ruby-agent).

## License

As of version 6.12 (released July 16, 2020), the New Relic Ruby agent is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for a copy of the license. For older agent versions, check the LICENSE file included with the source code.

The New Relic Ruby agent may use source code from third-party libraries. When used, these libraries will be outlined in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## Thank You

We always look forward to connecting with the community. We welcome [contributions](https://github.com/newrelic/newrelic-ruby-agent#contributing) to our source code and suggestions for improvements, and would love to hear about what you like and want to see in the future. 

Visit our [project board](https://github.com/orgs/newrelic/projects/84/) to see what's upcoming in a future release, what we're currently working on, and what we're planning next.

Thank you,

New Relic Ruby agent team
