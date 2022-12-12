# axe-core

[![License](https://img.shields.io/npm/l/axe-core.svg)](LICENSE)
[![Version](https://img.shields.io/npm/v/axe-core.svg)](https://www.npmjs.com/package/axe-core)
[![Total npm downloads](https://img.shields.io/npm/dt/axe-core.svg)](https://www.npmjs.com/package/axe-core)
[![Commits](https://img.shields.io/github/commit-activity/y/dequelabs/axe-core.svg)](https://github.com/dequelabs/axe-core/commits/develop)
[![GitHub contributors](https://img.shields.io/github/contributors/dequelabs/axe-core.svg)](https://github.com/dequelabs/axe-core/graphs/contributors)
[![Join our Slack chat](https://img.shields.io/badge/slack-chat-purple.svg?logo=slack)](https://accessibility.deque.com/axe-community)
[![Package Quality](http://npm.packagequality.com/shield/axe-core.svg)](http://packagequality.com/#?package=axe-core)

Axe is an accessibility testing engine for websites and other HTML-based user interfaces. It's fast, secure, lightweight, and was built to seamlessly integrate with any existing test environment so you can automate accessibility testing alongside your regular functional testing.

[Sign up for axe news](https://hubs.ly/H0fsN0b0) to get the latest on axe features, future releases, and events.

## The Accessibility Rules

Axe-core has different types of rules, for WCAG 2.0 and 2.1 on level A and AA, as well as a number of best practices that help you identify common accessibility practices like ensuring every page has an `h1` heading, and to help you avoid "gotchas" in ARIA like where an ARIA attribute you used will get ignored.

With axe-core, you can find **up to 50% of WCAG issues automatically**. Additionally, axe-core will return elements as "incomplete" where axe-core could not be certain, and manual review is needed. To further improve test coverage we recommend the [intelligent guided tests](https://www.youtube.com/watch?v=AtsX0dPCG_4&feature=youtu.be&ab_channel=DequeSystems) in the [axe Extension](https://www.deque.com/axe/browser-extensions/).

The complete list of rules, grouped WCAG level and best practice, can found in [doc/rule-descriptions.md](./doc/rule-descriptions.md).

## Getting started

First download the package:

```console
npm install axe-core --save-dev
```

Now include the javascript file in each of your iframes in your fixtures or test systems:

```html
<script src="node_modules/axe-core/axe.min.js"></script>
```

Now insert calls at each point in your tests where a new piece of UI becomes visible or exposed:

```js
axe
  .run()
  .then(results => {
    if (results.violations.length) {
      throw new Error('Accessibility issues found');
    }
  })
  .catch(err => {
    console.error('Something bad happened:', err.message);
  });
```

## Philosophy

The web can only become an accessible, inclusive space if developers are empowered to take responsibility for accessibility testing and accessible coding practices.

Automated accessibility testing is a huge timesaver, it doesn't require special expertise, and it allows teams to focus expert resources on the accessibility issues that really need them. Unfortunately, most accessibility tools are meant to be run on sites and applications that have reached the end of the development process and often don't give clear or consistent results, causing frustration and delays just when you thought your product was ready to ship.

Axe was built to reflect how web development actually works. It works with all modern browsers, tools, and testing environments a dev team might use. With axe, accessibility testing can be performed as part of your unit testing, integration testing, browser testing, and any other functional testing your team already performs on a day-to-day basis. Building accessibility testing into the early development process saves time, resources, and all kinds of frustration.

## About axe - our Manifesto

- Axe is open source.
- It returns zero false positives (bugs notwithstanding).
- It's designed to work on all modern browsers and with whatever tools, frameworks, libraries and environments you use today.
- It's actively supported by [Deque Systems](https://www.deque.com), a major accessibility vendor.
- It integrates with your existing functional/acceptance automated tests.
- It automatically determines which rules to run based on the evaluation context.
- Axe supports in-memory fixtures, static fixtures, integration tests and iframes of infinite depth.
- Axe is highly configurable.

## Supported Browsers

The [axe-core API](doc/API.md) fully supports the following browsers:

- Microsoft Edge v40 and above
- Google Chrome v42 and above
- Mozilla Firefox v38 and above
- Apple Safari v7 and above
- Internet Explorer v11

Support means that we will fix bugs and attempt to test each browser regularly. Only Firefox, Chrome, and Internet Explorer 11 are currently tested on every pull request.

There is limited support for JSDOM. We will attempt to make all rules compatible with JSDOM but where this is not possible, we recommend turning those rules off. Currently the `color-contrast` rule is known not to work with JSDOM.

We can only support environments where features are either natively supported or polyfilled correctly. We do not support the deprecated v0 Shadow DOM implementation.

## Contents of the API Package

The [axe-core API](doc/API.md) package consists of:

- `axe.js` - the JavaScript file that should be included in your web site under test (API)
- `axe.min.js` - a minified version of the above file

## Localization

Axe can be built using your local language. To do so, a localization file must be added to the `./locales` directory. This file must have be named in the following manner: `<langcode>.json`. To build axe using this locale, instead of the default, run axe with the `--lang` flag, like so:

`grunt build --lang=nl`

or equivalently:

`npm run build -- --lang=nl`

This will create a new build for axe, called `axe.<lang>.js` and `axe.<lang>.min.js`. If you want to build localized versions, simply pass in `--all-lang` instead.

To create a new translation for axe, start by running `grunt translate --lang=<langcode>`. This will create a json file fin the `./locales` directory, with the default English text in it for you to translate. We welcome any localization for axe-core. For details on how to contribute, see the Contributing section below. For details on the message syntax, see [Check Message Template](/docs/check-message-template.md).

To update existing translation file, re-run `grunt translate --lang=<langcode>`. This will add new messages used in English and remove messages which were not used in English.

Additionally, locale can be applied at runtime by passing a `locale` object to `axe.configure()`. The locale object must be of the same shape as existing locales in the `./locales` directory. For example:

```js
axe.configure({
  locale: {
    lang: 'de',
    rules: {
      accesskeys: {
        help: 'Der Wert des accesskey-Attributes muss einzigartig sein.'
      }
      // ...
    },
    checks: {
      abstractrole: {
        fail: 'Abstrakte ARIA-Rollen dürfen nicht direkt verwendet werden.'
      },
      'aria-errormessage': {
        // Note: doT (https://github.com/olado/dot) templates are supported here.
        fail:
          'Der Wert der aria-errormessage ${data.values}` muss eine Technik verwenden, um die Message anzukündigen (z. B., aria-live, aria-describedby, role=alert, etc.).'
      }
      // ...
    }
  }
});
```

## Supported ARIA Roles and Attributes.

Refer [axe-core ARIA support](./doc/aria-supported.md) for a complete list of ARIA supported roles and attributes by axe.

## Contributing

Read the [Proposing Axe-core Rules guide](./doc/rule-proposal.md)

Read the [documentation on the architecture](./doc/developer-guide.md)

Read the [documentation on contributing](CONTRIBUTING.md)

## Projects using axe-core

[List of projects using axe-core](doc/projects.md)

## Acknowledgements

Thanks to Dulin Marat for his [css-selector-parser](https://www.npmjs.com/package/css-selector-parser) implementation which is included for shadow DOM support.

Thanks to the [Slick Parser](https://github.com/mootools/slick/blob/master/Source/Slick.Parser.js) implementers for their contribution, we have used some of their algorithms in our shadow DOM support code.
