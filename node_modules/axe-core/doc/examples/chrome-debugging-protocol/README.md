# axe-chrome-debugging-protocol-example

This (very minimal) example demonstrates how to use `axe-core` with the [Chrome Debugging Protocol](https://chromedevtools.github.io/devtools-protocol/).

The example does not have feature parity with [`axe-webdriverjs`](https://github.com/dequelabs/axe-webdriverjs), and does not run on `<iframe>`s.

## To run the example

- Ensure Node v8+ is installed and on `PATH`
- Move to the `doc/examples/chrome-debugging-protocol` directory
- Run `npm install`
- Run `google-chrome --headless --remote-debugging-port=9222`. If you don't have a `google-chrome` binary, you can alias one with `alias google-chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'` on OSX.
- Run `node axe-cdp.js http://www.deque.com` to run `axe-core` via Puppeteer against http://www.deque.com and output results to the terminal
