const CDP = require('chrome-remote-interface');
const axeCore = require('axe-core');
const assert = require('assert');
const { parse: parseURL } = require('url');

// Cheap URL validation
const isValidURL = input => {
  const u = parseURL(input);
  return u.protocol && u.host;
};

const example = async url => {
  // eslint-disable-next-line new-cap
  const client = await CDP();
  const { Runtime: runtime, Page: page } = client;

  let results;

  try {
    await page.enable();
    await runtime.enable();

    await page.navigate({ url });

    // This function is injected into the browser and is responsible for
    // running `axe-core`.
    const browserCode = () => {
      /* eslint-env browser */
      return new Promise((resolve, reject) => {
        const axe = window.axe;
        if (!axe) {
          throw new Error('Unable to find axe-core');
        }

        // Finally, run axe-core
        axe
          .run()
          // For some reason, when resolving with an object, CDP ignores
          // its value (`results.result.value` is undefined). By
          // `JSON.stringify()`ing it, we can `JSON.parse()` it later on
          // and return a valid results set.
          .then(results => JSON.stringify(results))
          .then(resolve)
          .catch(reject);
      });
    };

    // Inject axe-core
    await runtime.evaluate({
      expression: axeCore.source
    });

    // Run axe-core
    const ret = await runtime.evaluate({
      expression: `(${browserCode})()`,
      awaitPromise: true
    });

    // re-parse
    results = JSON.parse(ret.result.value);
  } catch (err) {
    // Ensure we close the client before exiting the fn
    client.close();
    throw err;
  }
  client.close();
  return results;
};

// node axe-cdp.js <url>
const url = process.argv[2];
assert(isValidURL(url), 'Invalid URL');

example(url)
  .then(results => {
    console.log(results);
  })
  .catch(err => {
    console.error('Error running axe-core:', err.message);
    process.exit(1);
  });
