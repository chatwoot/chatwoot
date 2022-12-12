# axe-puppeteer-example

This (very minimal) example demonstrates how to use `axe-core` with [Puppeteer](https://github.com/GoogleChrome/puppeteer).

The example does not have feature parity with [`axe-webdriverjs`](https://github.com/dequelabs/axe-webdriverjs), and does not run on `<iframe>`s.

## To run the example

- Ensure Node v8+ is installed and on `PATH`
- Move to the `doc/examples/puppeteer` directory
- Run `npm install`
- Run `node axe-puppeteer.js http://www.deque.com` to run `axe-core` via Puppeteer against http://www.deque.com and output results to the terminal
