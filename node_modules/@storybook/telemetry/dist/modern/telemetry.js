const _excluded = ["payload", "metadata"];

function _objectWithoutPropertiesLoose(source, excluded) { if (source == null) return {}; var target = {}; var sourceKeys = Object.keys(source); var key, i; for (i = 0; i < sourceKeys.length; i++) { key = sourceKeys[i]; if (excluded.indexOf(key) >= 0) continue; target[key] = source[key]; } return target; }

import originalFetch from 'isomorphic-unfetch';
import retry from 'fetch-retry';
import { nanoid } from 'nanoid';
import { getAnonymousProjectId } from './anonymous-id';
const URL = 'https://storybook.js.org/event-log';
const fetch = retry(originalFetch);
let tasks = []; // getStorybookMetadata -> packagejson + Main.js
// event specific data: sessionId, ip, etc..
// send telemetry

const sessionId = nanoid();
export async function sendTelemetry(data, options = {
  retryDelay: 1000,
  immediate: false
}) {
  // We use this id so we can de-dupe events that arrive at the index multiple times due to the
  // use of retries. There are situations in which the request "5xx"s (or times-out), but
  // the server actually gets the request and stores it anyway.
  // flatten the data before we send it
  const {
    payload,
    metadata
  } = data,
        rest = _objectWithoutPropertiesLoose(data, _excluded);

  const context = {
    anonymousId: getAnonymousProjectId(),
    inCI: process.env.CI === 'true'
  };
  const eventId = nanoid();
  const body = Object.assign({}, rest, {
    eventId,
    sessionId,
    metadata,
    payload,
    context
  });
  let request;

  try {
    request = fetch(URL, {
      method: 'POST',
      body: JSON.stringify(body),
      headers: {
        'Content-Type': 'application/json'
      },
      retries: 3,
      retryOn: [503, 504],
      retryDelay: attempt => 2 ** attempt * options.retryDelay
    });
    tasks.push(request);

    if (options.immediate) {
      await Promise.all(tasks);
    } else {
      await request;
    }
  } catch (err) {//
  } finally {
    tasks = tasks.filter(task => task !== request);
  }
}