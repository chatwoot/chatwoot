# vue-router [![Build Status](https://img.shields.io/circleci/project/github/vuejs/vue-router/dev.svg)](https://circleci.com/gh/vuejs/vue-router)

> This is vue-router 3.0 which works only with Vue 2.0. For the 1.x router see the [1.0 branch](https://github.com/vuejs/vue-router/tree/1.0).

<h2 align="center">Supporting Vue Router</h2>

Vue Router is part of the Vue Ecosystem and is an MIT-licensed open source project with its ongoing development made possible entirely by the support of Sponsors. If you would like to become a sponsor, please consider:

- [Become a Sponsor on GitHub](https://github.com/sponsors/posva)
- [One-time donation via PayPal](https://paypal.me/posva)

<!-- <h3 align="center">Special Sponsors</h3> -->
<!--special start-->

<h4 align="center">Gold Sponsors</h4>

<p align="center">
  <a href="https://passionatepeople.io/" target="_blank" rel="noopener noreferrer">
    <img src="https://img2.storyblok.com/0x200/filters::format(webp)/f/86387/x/4cf6a70a8c/logo-white-text.svg" height="72px" alt="Passionate People">
  </a>

  <a href="https://vuejobs.com/?utm_source=vuerouter&utm_campaign=sponsor" target="_blank" rel="noopener noreferrer">
    <img src="docs/.vuepress/public/sponsors/vuejobs.png" height="72px" alt="VueJobs">
  </a>
</p>

<h4 align="center">Silver Sponsors</h4>

<p align="center">
  <a href="https://www.vuemastery.com" target="_blank" rel="noopener noreferrer">
    <img src="https://www.vuemastery.com/images/vuemastery.svg" height="42px" alt="Vue Mastery">
  </a>

  <a href="https://vuetifyjs.com" target="_blank" rel="noopener noreferrer">
    <img src="https://cdn.vuetifyjs.com/docs/images/logos/vuetify-logo-light-text.svg" alt="Vuetify" height="42px">
  </a>

  <a href="https://www.codestream.com/?utm_source=github&utm_campaign=vuerouter&utm_medium=banner" target="_blank" rel="noopener noreferrer">
    <img src="https://alt-images.codestream.com/codestream_logo_vuerouter.png" alt="CodeStream" height="42px">
  </a>

  <a href="https://birdeatsbug.com/?utm_source=vuerouter&utm_medium=sponsor&utm_campaign=silver" target="_blank" rel="noopener noreferrer">
    <img src="https://static.birdeatsbug.com/general/bird-logotype-150x27.svg" alt="Bird Eats bug" height="42px">
  </a>
</p>

<h4 align="center">Bronze Sponsors</h4>

<p align="center">
  <a href="https://storyblok.com" target="_blank" rel="noopener noreferrer">
    <img src="https://a.storyblok.com/f/51376/3856x824/fea44d52a9/colored-full.png" alt="Storyblok" height="32px">
  </a>

  <a href="https://nuxtjs.org" target="_blank" rel="noopener noreferrer">
    <img src="https://nuxtjs.org/logos/nuxtjs-typo-white.svg" alt="Storyblok" height="32px">
  </a>
</p>

---

Get started with the [documentation](http://router.vuejs.org), or play with the [examples](https://github.com/vuejs/vue-router/tree/dev/examples) (see how to run them below).

### Development Setup

```bash
# install deps
npm install

# build dist files
npm run build

# serve examples at localhost:8080
npm run dev

# lint & run all tests
npm test

# serve docs at localhost:8080
npm run docs
```

## Releasing

- `yarn run release`
  - Ensure tests are passing `yarn run test`
  - Build dist files `VERSION=<the_version> yarn run build`
  - Build changelog `yarn run changelog`
  - Commit dist files `git add dist CHANGELOG.md && git commit -m "[build $VERSION]"`
  - Publish a new version `npm version $VERSION --message "[release] $VERSION"
  - Push tags `git push origin refs/tags/v$VERSION && git push`
  - Publish to npm `npm publish`

## Questions

For questions and support please use the [Discord chat server](https://chat.vuejs.org) or [the official forum](http://forum.vuejs.org). The issue list of this repo is **exclusively** for bug reports and feature requests.

## Issues

Please make sure to read the [Issue Reporting Checklist](https://github.com/vuejs/vue/blob/dev/.github/CONTRIBUTING.md#issue-reporting-guidelines) before opening an issue. Issues not conforming to the guidelines may be closed immediately.

## Contribution

Please make sure to read the [Contributing Guide](https://github.com/vuejs/vue/blob/dev/.github/CONTRIBUTING.md) before making a pull request.

## Changelog

Details changes for each release are documented in the [`CHANGELOG.md file`](https://github.com/vuejs/vue-router/blob/dev/CHANGELOG.md).

## Stay In Touch

- For latest releases and announcements, follow on Twitter: [@vuejs](https://twitter.com/vuejs)

## License

[MIT](http://opensource.org/licenses/MIT)

Copyright (c) 2013-present Evan You

## Special Thanks

<a href="https://www.browserstack.com">
  <img src="/assets/browserstack-logo-600x315.png" height="80" title="BrowserStack Logo" alt="BrowserStack Logo" />
</a>

Special thanks to [BrowserStack](https://www.browserstack.com) for letting the maintainers use their service to debug browser specific issues.
