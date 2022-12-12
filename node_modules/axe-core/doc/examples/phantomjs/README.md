# PhantomJS README

This example demonstrates how to use axe with PhantomJS.

## To configure the example

- PhantomJS must be installed; please follow the directions at http://phantomjs.org/
  to install it.
- Run `npm install axe-core`

## To run the example

- Move to the `doc/examples/phantomjs` directory
- `phantomjs axe-phantom.js http://www.deque.com` to run axe in PhantomJS
  against http://www.deque.com and output results to the terminal
- `phantomjs axe-phantom.js http://www.deque.com results.json` to run axe in PhantomJS
  against http://www.deque.com and save results to `results.json`
