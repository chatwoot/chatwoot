# analytics.js-video-plugins

Add automatic Segment event tracking to popular video players.

## Introduction
Video plugins are built to hook into the lifecycle API of their corresponding video player and translate those events in to Segment events that adhere to the [Video Spec](https://segment.com/docs/spec/video/).

## Getting Started
Each individual plugin is stored in the `/plugins` directory. Plugins are built into a single module using Webpack [and output as a single commonJs module](https://webpack.js.org/configuration/output/#output-librarytarget) into the `/dist` directory. This file is then bundled into analytics.js via [analytics.js-private](https://github.com/segmentio/analytics.js-private) using Browserify. Each plugin is accessible at runtime at `window.analytics.plugins`.

## Contributing
If you're interested in contributing to the development of an existing player plugin or creating a new one, please reference our [contribution](https://github.com/segmentio/analytics.js-video-plugins/blob/master/CONTRIBUTING.md) guidelines.

## Releasing
To release, simply merge your changes into master on Github, pull them down locally into your master branch, and run `yarn release <major | minor | patch>`. This will automatically update `package.json` with the appropriate version bump, build a new dist file, push the updates to GitHub, and publish to npm.

Next, follow the instructions to [release analytics.js](https://paper.dropbox.com/doc/Releasing-Analytics.js-Deployment--AKqFN~w1oVkSR0xvHmHa8mK3Ag-ZFzuZSXuTQC) (note: you'll be bumping the version of `@segment/analytics.js-video-plugins` in that repo to the version you just published.
