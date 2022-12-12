const events = require("./index");
const axios = require("axios");
const cheerio = require("cheerio");
const ora = require("ora");
const fs = require("fs");

const BASE_URL = "https://developer.mozilla.org/en-US/docs/Web/Events";

function parseText(val) {
  if (val.match(/Yes/)) {
    return true;
  } else if (val.match(/No/)) {
    return false;
  }
}

function getValue($, name) {
  const text = $("dt, td")
    .filter(function() {
      return $(this).text() === name;
    })
    .next()
    .text();
  return parseText(text);
}

function writeToFile(val) {
  fs.writeFileSync(
    require.resolve("./dom-event-types.json"),
    JSON.stringify(val, null, 2)
  );
}

const obj = { ...events };

async function getInfo(event) {
  let res;
  try {
    res = await axios.get(`${BASE_URL}/${event}`);
  } catch (err) {
    return;
  }

  const $ = cheerio.load(res.data);

  const bubblesVal = getValue($, "Bubbles");
  const cancelableVal = getValue($, "Cancelable");

  if (bubblesVal === undefined) {
    delete obj[event].bubbles;
  }
  if (cancelableVal === undefined) {
    delete obj[event].cancelable;
  }
}

(async () => {
  const spinner = ora("Scraping MDN").start();
  for (const event of Object.keys(events)) {
    await getInfo(event);
  }
  spinner.stop();
  console.log("Scraping complete");
  writeToFile(obj);
})();
