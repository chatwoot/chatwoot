# email-provider-info

Find email provider service based on the email address.

[![JavaScript Tests](https://github.com/fnando/email-provider-info/workflows/js-tests/badge.svg)](https://github.com/fnando/email-provider-info)
[![Ruby Tests](https://github.com/fnando/email-provider-info/workflows/ruby-tests/badge.svg)](https://github.com/fnando/email-provider-info)
[![NPM](https://img.shields.io/npm/v/@fnando/email-provider-info.svg)](https://npmjs.org/package/@fnando/email-provider-info)
[![NPM](https://img.shields.io/npm/dt/@fnando/email-provider-info.svg)](https://npmjs.org/package/@fnando/email-provider-info)
[![Gem](https://img.shields.io/gem/v/email-provider-info.svg)](https://rubygems.org/gems/email-provider-info)
[![Gem](https://img.shields.io/gem/dt/email-provider-info.svg)](https://rubygems.org/gems/email-provider-info)
[![MIT License](https://img.shields.io/:License-MIT-blue.svg)](https://tldrlegal.com/license/mit-license)

Supported services:

- AOL
- Apple iCloud
- BOL
- Fastmail
- Gmail
- GMX
- Hey
- Mail.ru
- Outlook
- ProtonMail
- Tutanota
- UOL
- Yahoo!
- Yandex
- Zoho

## Installation

This package is available as a NPM and Rubygems package. To install it, use the
following command:

### JavaScript

```bash
npm install @fnando/email-provider-info --save
```

If you're using Yarn (and you should):

```bash
yarn add @fnando/email-provider-info
```

### Ruby

```bash
gem install email_provider_info
```

Or add the following line to your project's Gemfile:

```ruby
gem "email-provider-info"
```

## Usage

### JavaScript

```js
import { getEmailProvider } from "@fnando/email-provider-info";

const { name, url } = getEmailProvider("example@gmail.com");

if (url) {
  // Do something
}
```

### Ruby

```ruby
require "email_provider_info"

provider = EmailProviderInfo.call("email@gmail.com")

if provider
  # Do something
end
```

### Motivation

The idea behind this package is enabling something like this, where users can go
to their email service provider with just one click.

![Example: Show button that goes straight to Gmail](https://raw.githubusercontent.com/fnando/email-provider-info/main/sample.png)

## Maintainer

- [Nando Vieira](https://github.com/fnando)

## Contributors

- https://github.com/fnando/email-provider-info/contributors

## Contributing

For more details about how to contribute, please read
https://github.com/fnando/email-provider-info/blob/main/CONTRIBUTING.md.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT). A copy of the license can be
found at https://github.com/fnando/email-provider-info/blob/main/LICENSE.md.

## Code of Conduct

Everyone interacting in the email-provider-info project's codebases, issue
trackers, chat rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/fnando/email-provider-info/blob/main/CODE_OF_CONDUCT.md).
