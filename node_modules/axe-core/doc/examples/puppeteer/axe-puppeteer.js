const puppeteer = require('puppeteer');
const axeCore = require('axe-core');
const { parse: parseURL } = require('url');
const assert = require('assert');

// Cheap URL validation
const isValidURL = input => {
  const u = parseURL(input);
  return u.protocol && u.host;
};

// node axe-puppeteer.js <url>
const url = process.argv[2];
assert(isValidURL(url), 'Invalid URL');

const main = async url => {
  let browser;
  let results;
  try {
    // Setup Puppeteer
    browser = await puppeteer.launch();

    // Get new page
    const page = await browser.newPage();
    await page.goto(url);

    // Inject and run axe-core
    const handle = await page.evaluateHandle(`
			// Inject axe source code
			${axeCore.source}
			// Run axe
			axe.run()
		`);

    // Get the results from `axe.run()`.
    results = await handle.jsonValue();
    // Destroy the handle & return axe results.
    await handle.dispose();
  } catch (err) {
    // Ensure we close the puppeteer connection when possible
    if (browser) {
      await browser.close();
    }

    // Re-throw
    throw err;
  }

  await browser.close();
  return results;
};

main(url)
  .then(results => {
    console.log(results);
  })
  .catch(err => {
    console.error('Error running axe-core:', err.message);
    process.exit(1);
  });
